// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./AuctionHouse.sol";

contract MarketPlace is AuctionHouse{
    // address payable private s_beneficiary;
    // uint256 private s_auctionEndTime;
    // address private s_highestBidder;
    // uint256 private s_highestBid;

    // mapping(address => uint256) public pendingReturns;
    // bool ended = false;

    // event HighestBidIncrease(address bidder, uint256 amount);
    // event AuctionEnded(address winner, uint256 amount);

    // error AuctionHasEnded();
    // error AuctionNotEnded();
    // error AuctionEndAlreadyCalled();
    // error NeedHigherBid(uint256 highest_bid);
    // error TransferFailed();

    constructor() AuctionHouse(3600){
        
    }

}
