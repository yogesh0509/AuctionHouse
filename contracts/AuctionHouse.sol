// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionHouse is Ownable{
    uint256 private s_auctionEndTime;
    address private s_highestBidder;
    uint256 private s_highestBid;

    mapping(address => uint256) public pendingReturns;
    bool ended = false;

    event HighestBidIncrease(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    error AuctionHasEnded();
    error AuctionNotEnded();
    error AuctionEndAlreadyCalled();
    error NeedHigherBid(uint256 highest_bid);
    error TransferFailed();

    constructor(uint256 _biddingTime) {
        s_auctionEndTime = _biddingTime;
    }

    function bid() public payable {
        if (block.timestamp > s_auctionEndTime) {
            revert AuctionHasEnded();
        }

        if (msg.value <= s_highestBid) {
            revert NeedHigherBid(s_highestBid);
        }

        if (s_highestBid != 0) {
            pendingReturns[s_highestBidder] += s_highestBid;
        }

        s_highestBidder = msg.sender;
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

    function auctionEnd(address payable _beneficiary) public onlyOwner{
        if(block.timestamp < s_auctionEndTime){
            revert AuctionNotEnded();
        }
        if(ended){
            revert AuctionEndAlreadyCalled();
        }
        ended = true;
        emit AuctionEnded(s_highestBidder, s_highestBid);

        (bool success, ) = (_beneficiary).call{value: s_highestBid}("");
            if (!success) {
                revert TransferFailed();
            }
    }
}
