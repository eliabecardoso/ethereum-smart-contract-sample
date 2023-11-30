// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { NFTBase } from './NFTBase.sol';

struct Offer {
  address buyer;
  uint value;
  uint unlockTime;
}

contract NTFAuction {
  address public auctioneer;
  uint8 public auctioneerTax;
  mapping(uint tokenId => Offer buyer) public offers;

  event NewOffer(address from, uint value, uint8 tokenId);

  event WithdrawOffer(address to, uint value, uint8 tokenId);

  modifier checkOffer(uint offerValue) {
    require(offerValue != 0, 'Offer must be more than zero');
    _;
  }

  modifier checkCommitOffer(uint8 tokenId) {
    require(offers[tokenId].buyer != address(0), 'No one offer');
    // require(block.timestamp >= offers[tokenId].unlockTime, 'Unlock time not reached'); make sense?
    _;
  }

  constructor(address _auctioneer, uint8 _auctioneerTax) {
    auctioneer = _auctioneer;
    auctioneerTax = _auctioneerTax;
  }

  function offer(address buyer, uint offerValue, uint8 tokenId) checkOffer(offerValue) internal {
    if (offers[tokenId].buyer != address(0)) {
      require(offerValue > offers[tokenId].value, 'Value not reached');

      withdraw(tokenId, offers[tokenId].buyer);
    }

    uint lockTime = block.timestamp + 60;

    offers[tokenId] = Offer(buyer, offerValue, lockTime);

    emit NewOffer(buyer, offerValue, tokenId);
  }

  function resetOffer(uint8 tokenId) internal {
    offers[tokenId] = Offer(address(0), 0, 0);
  }

  function removeOffer(address exbuyer, uint8 tokenId) internal {
    payable(exbuyer).transfer(offers[tokenId].value);
    resetOffer(tokenId);
  }

  function withdraw(uint8 tokenId, address to) internal {
    Offer memory _offer = offers[tokenId];

    removeOffer(to, tokenId);

    emit WithdrawOffer(to, _offer.value, tokenId);
  }

  function withdraw(uint8 tokenId) external {
    Offer memory _offer = offers[tokenId];

    require(msg.sender == _offer.buyer, 'You are not the buyer');
    require(block.timestamp >= _offer.unlockTime, 'Unlock time not reached');

    removeOffer(msg.sender, tokenId);

    emit WithdrawOffer(msg.sender, _offer.value, tokenId);
  }
}
