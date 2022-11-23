// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "hardhat/console.sol";

contract AuctionHouse {
    uint256 private s_auctionEndTime;
    address private s_highestBidder;
    uint256 private s_highestBid;
    uint256 private s_lastTimeStamp;

    mapping(address => uint256) public pendingReturns;
    bool ended = false;

    event HighestBidIncrease(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event AuctionStarted();

    error AuctionHasEnded();
    error AuctionNotEnded();
    error AuctionEndAlreadyCalled();
    error NeedHigherBid(uint256 highest_bid);
    error TransferFailed();

    constructor(uint256 _biddingTime) {
        s_auctionEndTime = _biddingTime;
    }

    function start() external{
        if (block.timestamp - s_lastTimeStamp < s_auctionEndTime) {
            revert AuctionNotEnded();
        }
        s_lastTimeStamp = block.timestamp;
        ended = false;
        s_highestBid = 0;
        s_highestBidder = address(0);
        emit AuctionStarted();
    }

    function bid(address bidder) public payable virtual {
        if (block.timestamp - s_lastTimeStamp > s_auctionEndTime) {
            revert AuctionHasEnded();
        }

        if (msg.value <= s_highestBid) {
            revert NeedHigherBid(s_highestBid);
        }

        if (s_highestBid != 0) {
            pendingReturns[s_highestBidder] += s_highestBid;
        }

        s_highestBidder = bidder;
        s_highestBid = msg.value;
        emit HighestBidIncrease(s_highestBidder, s_highestBid);
    }

    function withdraw() public {
        uint256 amount = pendingReturns[msg.sender];

        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            (bool success, ) = (msg.sender).call{value: amount}("");
            if (!success) {
                revert TransferFailed();
            }
        }
    }

    // auctionEnd and auctionStart can only be called by Marketplace contract

    function auctionEnd(address payable _beneficiary) external returns(address, uint256){
        if (block.timestamp - s_lastTimeStamp < s_auctionEndTime) {
            revert AuctionNotEnded();
        }
        if (ended) {
            revert AuctionEndAlreadyCalled();
        }
        ended = true;
        emit AuctionEnded(s_highestBidder, s_highestBid);
        (bool success, ) = (_beneficiary).call{value: s_highestBid}("");
        if (!success) {
            revert TransferFailed();
        }
        return (getHighestBidder(), getHighestBid());
    }

    function getHighestBidder() public view returns (address) {
        return s_highestBidder;
    }

    function getHighestBid() public view returns (uint256) {
        return s_highestBid;
    }

    function getAuctionEndtime() public view returns (uint256) {
        return s_auctionEndTime;
    }

    fallback() external payable {}
    receive() external payable {}
}
