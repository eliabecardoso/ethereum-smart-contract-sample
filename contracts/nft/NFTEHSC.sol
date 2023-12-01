// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { NFTBase } from './NFTBase.sol';
import { NTFAuction } from './NTFAuction.sol';

contract NFTEHSC is NTFAuction, NFTBase {
  modifier checkValue(uint minValue) {
    require(msg.value >= minValue, 'Value not reached');
    _;
  }

  modifier checkBalance() {
    require(address(this).balance > 0, 'Oops...');
    _;
  }

  constructor(address owner, uint8 royaltiesTax, address auctioneer, uint8 auctioneerTax)
    NTFAuction(auctioneer, auctioneerTax)
    NFTBase(royaltiesTax, owner) { }

  function mint() checkValue(1000) external payable {
    bytes32 ipfsHash = keccak256('QmXExS4BMc1YrH6iWERyryFcDWkvobxryXSwECLrcd7Y1H'); // external info (e.g. 'QmXExS4BMc1YrH6iWERyryFcDWkvobxryXSwECLrcd7Y1H')

    _mint(ipfsHash);
    payable(nftOwner).transfer(msg.value);
  }

  function bid(uint8 tokenId) checkValue(100) checkTransfer(tokenId) public payable {
    _bid(msg.sender, msg.value, tokenId);
  }

  function transfer(uint8 tokenId) checkOwner(tokenId) checkBalance() checkCommitBidder(tokenId) checkTransfer(tokenId) external {
    uint valueToOwner = highestBidder[tokenId].value / royaltiesTax; // 1000 / 1.1 (10%) = 909.09
    uint valueToNftOwner = (highestBidder[tokenId].value - valueToOwner) / auctioneerTax; // (1000 - 909.09) / 1.1 (10%) = 82.64
    uint valueToAuctioneer = highestBidder[tokenId].value - valueToOwner - valueToNftOwner; // 1000 - 909.09 - 82.64 = 8.26

    payable(msg.sender).transfer(valueToOwner);
    payable(nftOwner).transfer(valueToNftOwner);
    payable(auctioneer).transfer(valueToAuctioneer);

    _transfer(highestBidder[tokenId].bidder, tokenId);
    _resetBidder(tokenId);
    this.unNegotiate(tokenId);
  }
}
