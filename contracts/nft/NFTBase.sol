// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

struct TokenOwner {
  address owner;
  bytes32 ipfsHash;
  bool negotiate;
  // uint256 flags; // flags in bitmaps mode
  uint value;
}

contract NFTBase {
  uint8 public tokenCounter = 0;
  address public nftOwner;
  uint8 public royaltiesTax;
  mapping(uint => TokenOwner) public tokenOwner;

  modifier checkOwner(uint tokenId) {
    require(msg.sender == tokenOwner[tokenId].owner, 'You are not the owner');
    _;
  }

  modifier checkTransfer(uint8 tokenId) {
    require(tokenOwner[tokenId].negotiate, 'NFT non-negotiable');
    _;
  }

  event Mint(address nftOwner, uint8 tokenId, bytes32 ipfsHash);
  event Transfer(address from, address to, uint8 tokenId);

  constructor(uint8 _royaltiesTax, address _owner) {
    nftOwner = _owner != address(0) ? _owner : msg.sender;
    royaltiesTax = _royaltiesTax;
  }

  function _mint(bytes32 ipfsHash) internal {
    tokenOwner[++tokenCounter] = TokenOwner(msg.sender, ipfsHash, false, 0);

    emit Mint(nftOwner, tokenCounter, ipfsHash);
  }

  function _transfer(address to, uint8 tokenId) internal {
    tokenOwner[tokenId].owner = to;

    emit Transfer(msg.sender, to, tokenId);
  }

  function negotiate(uint8 tokenId, uint value) checkOwner(tokenId) external {
    tokenOwner[tokenId].negotiate = true;
    tokenOwner[tokenId].value = value;
  }

  function unNegotiate(uint8 tokenId) checkOwner(tokenId) external {
    tokenOwner[tokenId].negotiate = false;
    tokenOwner[tokenId].value = 0;
  }

  function balance() external view returns(uint) {
    return address(this).balance;
  }
}
