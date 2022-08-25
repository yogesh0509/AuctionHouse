// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./AuctionHouse.sol";
import "hardhat/console.sol";

contract Marketplace is AuctionHouse {
    struct playerBought {
        address player;
        uint256 price;
    }

    uint256 private s_totalBuyers;
    mapping(address => bool) public Buyer;
    mapping(address => mapping(uint256 => playerBought)) public BuyerTransactions;
    mapping(address => uint256) public BuyerTransactionCount;

    // Auction Starts - calls the AuctionHouse Contract. sets the time for auction of each contract. return the winner of the auction.
    // pass the player being auctioned.
    // constructor - gets all the registered players.

    modifier checkbuyer(address registrant) {
        if (Buyer[registrant] == true) {
            console.log("Buyer already registered");
            revert BuyerAlreadyRegistered();
        }
        _;
    }

    error BuyerAlreadyRegistered();

    event BuyerRegistered(address registrant);

    constructor() AuctionHouse(3600) {

    }

    function register(address registrant) public checkbuyer(registrant){
        Buyer[registrant] = true;
        emit BuyerRegistered(registrant);
    }

}
