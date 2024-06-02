// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

contract AucEngine{
    address public owner;
    uint constant DURATION = 2 days;
    uint constant FEE = 10;

    struct Auction{
        // uint id;
        address payable seller;
        uint startPrice;
        uint finalPrice;
        uint startAt;
        uint endsAt;
        uint discountRate;
        string item;
        bool stopped;
    }

    Auction[] public auctions;
    // mapping (uint => Auction) auctions;

    event AuctionCreated(uint index, string  item, uint _startingPrice, uint duration);

    event AuctionEnded(uint finalPrice, uint price, address winner);

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not allowed to do this");
        _;
    }


    constructor(){
        owner = msg.sender;
    }

    function createAuction(uint _startingPrice, uint _discountRate, string calldata _item, uint _duration) external {
        uint duration = _duration == 0 ? DURATION : _duration;
        require(_startingPrice >= _discountRate * _duration, "incorrect starting price");
        Auction memory newAauction  = Auction({
            seller: payable(msg.sender),
            startPrice: _startingPrice,
            finalPrice: _startingPrice,
            startAt: block.timestamp,
            endsAt: block.timestamp + _duration,
            discountRate: _discountRate,
            item: _item,
            stopped: false
        });
        auctions.push(newAauction);

        emit AuctionCreated(auctions.length -1, _item, _startingPrice, duration);
    }


    function getPriceFor(uint index) public view returns(uint){
        Auction memory auction = auctions[index];
        require(!auction.stopped, "auction already stopped");
        require(block.timestamp < auction.endsAt, "auction already ended");
        uint elapsed = block.timestamp - auction.startAt;
        uint discount = elapsed * auction.discountRate;
        return auction.startPrice - discount;
    }

    function buy(uint index) external payable {
        Auction storage auction = auctions[index];
        require(block.timestamp < auction.endsAt, "Auction already ended");
        require(!auction.stopped, "Auction already stopped");
        uint price = getPriceFor(index);
        require(msg.value >= price, "Not enough funds to buy this item");
        auction.stopped = true;
        auction.finalPrice = price;
        uint refund = msg.value - price;
        if (refund > 0){
            payable (msg.sender).transfer(refund);
        }

        payable (auction.seller).transfer(price - ((price * FEE) / 100));
        emit AuctionEnded(index, price, msg.sender);
    }

    function withdrawAll() external onlyOwner{
        
        payable (owner).transfer(address(this).balance);
    }
}