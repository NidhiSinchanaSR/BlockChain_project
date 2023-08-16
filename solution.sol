// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Eauction {

    // Define struct Auction
    // user-defined data type that allows you to group together 
    // related variables of different data types into a single object
    struct Auction {
        uint256 auctionId; // unique auction id
        string itemName; // name of the item
        string itemDescription; // description of the item
        uint256 start; // unix timestamp of auction's start time
        uint256 end; // unix timestamp of auction's end time
        address seller; // address of seller
        address highestBidder; // address of highest bidder
        uint256 highestBid; // highest bid
        address escrow; // address of escrow

        // gotFundsFromHighestBidder is a flag
        // it will become true when highest bidder sends money to contract
        bool gotFundsFromHighestBidder;

        // transferredFunds is a flag
        // it will become true when escrow sends money from contract to seller or returns highest bidder's money
        bool transferredFunds;
    }

    // Define a map
    // it contains all the auctions referenced by auction ids
    mapping(uint256 => Auction) public auctions;

    // keeps the count of auctions
    uint256 public auctionCount;

    // Function to create auction
    // it will be used by seller to create auctions
    function createAuction(
    string memory _itemName,
    string memory _itemDescription,
    uint256 _start,
    uint256 _end,
    address _escrow
) public {
    require(_start >= block.timestamp, "Auction must start in the future");
    require(_end > _start, "Auction end must be after auction start");

    // Generate a unique auction ID
    uint256 _auctionId = auctionCount++;

    // Set the details of auction
    auctions[_auctionId].auctionId = _auctionId;
    auctions[_auctionId].itemName = _itemName;
    auctions[_auctionId].itemDescription = _itemDescription;
    auctions[_auctionId].start = _start;
    auctions[_auctionId].end = _end;
    auctions[_auctionId].seller = msg.sender;
    auctions[_auctionId].highestBidder = address(0);
    auctions[_auctionId].highestBid = 0;
    auctions[_auctionId].escrow = _escrow;
    auctions[_auctionId].gotFundsFromHighestBidder = false;
    auctions[_auctionId].transferredFunds = false;
    }

    // Function to place bids
    // Bidders will use this to place bids
    function placeBid(uint256 _auctionId, uint256 _bid) public {
        Auction memory auction = auctions[_auctionId];
        require(auction.auctionId == _auctionId, "Invalid auction ID");
        require(block.timestamp >= auction.start, "Auction has not yet started");
        require(block.timestamp <= auction.end, "Auction has already ended");
        require(_bid > auction.highestBid, "Bid must be higher than current highest bid");

        // update the value of highest bidder and highest bid
        auctions[_auctionId].highestBidder = msg.sender;
        auctions[_auctionId].highestBid = _bid;
    }

    // Function to get money from highest bidder
    // highest bidder will send money to contract using this function
    function getFundsFromHighestBidder(uint256 _auctionId) public payable {
        Auction memory auction = auctions[_auctionId];
        require(auction.auctionId == _auctionId, "Invalid auction ID");
        require(block.timestamp > auction.end, "Auction has not yet ended");  
        require(auction.highestBidder != address(0), "No highest bidder");
        require(auction.highestBidder == msg.sender, "Only highest bidder can send money");
        require(msg.value == auction.highestBid, "Sent money should be equal to the highest bid");
        require(auction.gotFundsFromHighestBidder == false, "Highest bidder has already sent the funds");

        // Set gotFundsFromHighestBidder flag
        auctions[_auctionId].gotFundsFromHighestBidder = true;
    }

    // Function to send money to seller or return money to highest bidder
    // only escrow will be able to perform this action
    // if the seller sends goods to the highest bidder, escrow will send money to seller
    // otherwise escrow will return highest bidder's money
    function transferFunds(uint256 _auctionId, address fundsReceiver) public {
        Auction memory auction = auctions[_auctionId];
        require(auction.auctionId == _auctionId, "Invalid auction ID");
        require(fundsReceiver == auction.seller || fundsReceiver == auction.highestBidder, "Only the seller or highest bidder can be recipient");
        require(msg.sender == auction.escrow, "Only escrow can perform this action");
        require(auction.gotFundsFromHighestBidder == true, "Not received funds from highest bidder");  
        require(address(this).balance >= auction.highestBid, "Insufficient funds in the contract");
        require(auction.transferredFunds == false, "Escrow has already transferred the funds");
        
        // Sending the money to seller or returning to highest bidder
        payable(fundsReceiver).transfer(auction.highestBid);

        // Set transferredFunds flag
        auctions[_auctionId].transferredFunds = true;
    }
}