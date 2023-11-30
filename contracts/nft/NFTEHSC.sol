// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { NFTBase } from './NFTBase.sol';
import { NTFAuction } from './NTFAuction.sol';

contract NFTEHSC is NTFAuction, NFTBase {
  modifier checkValue(uint minValue) {
    require(msg.value >= minValue, 'Value not reached');
    _;
  }

  constructor(address owner, uint8 royaltiesTax, address auctioneer, uint8 auctioneerTax)
    NTFAuction(auctioneer, auctioneerTax)
    NFTBase(royaltiesTax, owner) { }

  function mint() checkValue(1000) external payable {
    bytes32 ipfsHash = bytes32(block.timestamp); // external info

    mint(ipfsHash);
    payable(nftOwner).transfer(msg.value);
  }

  function offer(uint8 tokenId) checkValue(100) public payable {
    offer(msg.sender, msg.value, tokenId);
  }

  function transfer(uint8 tokenId) checkOwner(tokenId) checkCommitOffer(tokenId) checkTransfer(tokenId) external payable {
    uint valueToOwner = offers[tokenId].value / royaltiesTax; // 1000 / 1.1 = 909.09
    uint valueToNftOwner = (offers[tokenId].value - valueToOwner) / auctioneerTax; // (1000 - 909.09) / 1.1 = 82.64
    uint valueToAuctioneer = offers[tokenId].value - valueToOwner - valueToNftOwner; // 1000 - 909.09 - 82.64 = 8.26

    payable(msg.sender).transfer(valueToOwner);
    payable(nftOwner).transfer(valueToNftOwner);
    payable(auctioneer).transfer(valueToAuctioneer);

    transfer(offers[tokenId].buyer, tokenId);
    resetOffer(tokenId);
  }
}
