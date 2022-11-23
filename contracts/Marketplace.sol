// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AuctionHouse.sol";
import "./IdentityNft.sol";
import "hardhat/console.sol";

contract Marketplace is Ownable, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    struct playerBought {
        uint256 tokenId;
        uint256 price;
    }

    // deciding the winner

    mapping(address => bool) private Buyer; // true if address(registrant) is present in the mapping
    // may change it
    mapping(address => mapping(uint256 => playerBought)) // players bought by each registrant
        private BuyerTransactions;
    mapping(address => uint256) private BuyerTransactionCount; // no. of players bought by each registrant

    address[] public BuyerCount;
    uint256 public s_totalBuyerCount;
    uint256 public s_playerCount;
    uint256 public s_currentplayercount;
    uint256 public s_currentAuctionTime;
    uint256 public s_biddingPrice = 1e15;
    bool public s_auctionState;

    // address public s_AuctionHouse_addr;
    AuctionHouse private s_AuctionHouseContract;

    bytes32 private jobId;
    uint256 private fee;

    uint256 public constant AUCTION_TIME = 86400;

    modifier registeredBuyer() {
        if (Buyer[msg.sender] == true) {
            revert BuyerAlreadyRegistered();
        }
        _;
    }

    modifier NotRegisteredBuyer() {
        if (Buyer[msg.sender] != true) {
            revert BuyerNotRegistered();
        }
        _;
    }

    modifier checkauctionState() {
        if (s_auctionState) {
            revert AuctionIsOpen();
        }
        _;
    }

    error BuyerAlreadyRegistered();
    error BuyerNotRegistered();
    error AuctionIsOpen();
    error TransferFailed();

    event BuyerRegistered(address registrant);
    event AuctionEnded(address winner, uint256 amount);
    event AuctionStarted();
    event RequestFulfilled(bytes32 indexed requestId, bytes indexed data);
    event HighestBidIncrease(uint256 tokenId, address bidder, uint256 amount);

    constructor(address payable _addr1, address payable _addr2) {
        // s_AuctionHouse_addr = _addr2;
        IdentityNft Nft = IdentityNft(_addr1);
        s_AuctionHouseContract = AuctionHouse(_addr2);
        s_playerCount = Nft.getTokenCounter();
        s_auctionState = false;
        s_currentAuctionTime = block.timestamp + AUCTION_TIME; // 1 Day

        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
        jobId = "7da2702f37fd48e5b1b9a5715e3509b6";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    function register() public registeredBuyer checkauctionState {
        Buyer[msg.sender] = true;
        BuyerCount.push(msg.sender);
        s_totalBuyerCount += 1;
        emit BuyerRegistered(msg.sender);
    }

    function startAuction() public onlyOwner {
        s_auctionState = true;
        s_currentAuctionTime = block.timestamp;
        s_AuctionHouseContract.start();
        emit AuctionStarted();
    }

    function bid() public payable NotRegisteredBuyer {
        s_AuctionHouseContract.bid{value: msg.value}(msg.sender);
        if (s_biddingPrice >= 1e18) {
            s_biddingPrice += 5e17;
        } else {
            s_biddingPrice += 5e14;
        }
        // emit an event with tokenId
    }

    function fulfillBytes(bytes32 requestId, bytes memory bytesData)
        public
        recordChainlinkFulfillment(requestId)
    {
        emit RequestFulfilled(requestId, bytesData);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        external
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        if (s_currentplayercount < s_playerCount) {
            upkeepNeeded = (block.timestamp - s_currentAuctionTime >=
                AUCTION_TIME);
        } else {
            upkeepNeeded = true;
        }
    }

    function performUpkeep(
        bytes calldata /*performData*/
    ) external {
        if (s_currentplayercount < s_playerCount) {
            if (
                (block.timestamp - s_currentAuctionTime) >= AUCTION_TIME &&
                !s_auctionState
            ) {
                startAuction();
            } else if (
                (block.timestamp - s_currentAuctionTime) >= AUCTION_TIME &&
                s_auctionState
            ) {
                s_auctionState = false;
                s_currentAuctionTime = block.timestamp;
                (
                    address s_highestBidder,
                    uint256 s_highestBid
                ) = s_AuctionHouseContract.auctionEnd(payable(address(this)));
                emit AuctionEnded(s_highestBidder, s_highestBid);

                // need to write tests for these...

                BuyerTransactions[s_highestBidder][
                    BuyerTransactionCount[s_highestBidder]
                ] = playerBought(s_currentplayercount, s_highestBid);
                BuyerTransactionCount[s_highestBidder]++;
                s_currentplayercount++;
            }
        } else if (s_currentplayercount == s_playerCount) {
            console.log("inside chainlink api");

            Chainlink.Request memory req = buildChainlinkRequest(
                jobId,
                address(this),
                this.fulfillBytes.selector
            );
            req.add(
                "get",
                "https://46ed-2409-4071-d10-3785-d946-f309-887c-d38.in.ngrok.io/playerdata"
            );
            req.add("path", "abi");
            sendChainlinkRequest(req, fee);
        }
    }

    function getBuyers() public view returns(address[] memory){
        return BuyerCount;
    }

    function getPlayersPurchased(address player) public view returns(uint256){
        return BuyerTransactionCount[player];
    }

    function moneyspent(address player) public view returns(uint256){
        uint256 sum = 0;
        for(uint256 i = 0; i< BuyerTransactionCount[player]; i++){
            sum += BuyerTransactions[player][i].price;
        }
        return sum;
    }

    fallback() external payable {}

    receive() external payable {}
    // revert eth sent without any function
}
