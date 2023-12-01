// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

struct Bidder {
  address bidder;
  uint value;
  uint unlockTime;
  bool unlock;
}

contract NTFAuction {
  address public auctioneer;
  uint8 public auctioneerTax;
  mapping(uint tokenId => Bidder highestBidder) public highestBidder;

  event NewBidder(address from, uint value, uint8 tokenId);

  event WithdrawBidder(address to, uint value, uint8 tokenId);

  modifier checkBidder(uint bidValue) {
    require(bidValue != 0, 'Bidder must be more than zero');
    _;
  }

  modifier checkCommitBidder(uint8 tokenId) {
    require(highestBidder[tokenId].bidder != address(0), 'No one bid');
    // require(block.timestamp >= highestBidder[tokenId].unlockTime, 'Unlock time not reached'); make sense?
    _;
  }

  modifier checkSelfWithdraw(uint8 tokenId) {
    Bidder memory bidder = highestBidder[tokenId];

    require(msg.sender == bidder.bidder, 'You are not the bidder');
    require(msg.value >= 100, 'Withdraw Tax not reached (100 wei)');
    require(block.timestamp > bidder.unlockTime, 'Unlock time not reached');
    require(bidder.unlock, 'Bid locked');
    _;
  }

  modifier checkAuctioneer() {
    require(msg.sender == auctioneer, 'You are not the Auctioneer');
    _;
  }

  constructor(address _auctioneer, uint8 _auctioneerTax) {
    auctioneer = _auctioneer;
    auctioneerTax = _auctioneerTax;
  }

  function _bid(address bidder, uint bidValue, uint8 tokenId) checkBidder(bidValue) internal {
    require(address(bidder).balance >= bidValue, 'Your balance must be more than bid value');

    if (highestBidder[tokenId].bidder != address(0)) {
      require(bidValue > highestBidder[tokenId].value, 'Value not reached');

      _withdraw(tokenId, highestBidder[tokenId].bidder);
    }

    uint lockTime = block.timestamp + 60;
    highestBidder[tokenId] = Bidder(bidder, bidValue, lockTime, true);

    emit NewBidder(bidder, bidValue, tokenId);
  }

  function _resetBidder(uint8 tokenId) internal {
    // highestBidder[tokenId] = Bidder(address(0), 0, 0);
    delete highestBidder[tokenId];
  }

  function _removeBidder(address exHighestBidder, uint8 tokenId) internal {
    payable(exHighestBidder).transfer(highestBidder[tokenId].value);
    _resetBidder(tokenId);
  }

  function _withdraw(uint8 tokenId, address to) internal {
    Bidder memory bidder = highestBidder[tokenId];

    _removeBidder(to, tokenId);

    emit WithdrawBidder(to, bidder.value, tokenId);
  }

  function withdraw(uint8 tokenId) checkSelfWithdraw(tokenId) external payable {
    _removeBidder(msg.sender, tokenId);

    emit WithdrawBidder(msg.sender, highestBidder[tokenId].value, tokenId);
  }

  function unlockBid(uint8 tokenId) checkAuctioneer external {
    highestBidder[tokenId].unlock = true;
  }
}
