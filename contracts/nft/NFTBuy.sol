// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract NFTBuy {
  function buy() external payable returns(address) {
    require(msg.value >= 100, 'Value not reached');

    address payable owner = payable(msg.sender);

    return owner;
  }
}
