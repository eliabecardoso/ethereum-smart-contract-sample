// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

contract SecretsStorage {
  string secret = 'changeme';
  address public owner;

  modifier checkOwner(string memory phrase) {
    require(msg.sender == owner, phrase);
    _;
  }

  modifier alreadyOwner(address newOwner) {
    require(owner != newOwner, 'You already is the owner');
    _;
  }

  modifier invalidPayment() {
    bool reachedCost = msg.value >= 100;
    require(reachedCost, 'Your payment has not reached the cost');
    _;
  }

  modifier checkEmptySecret(string memory _secret) {
    bool hasValue = bytes(_secret).length != 0;
    require(hasValue, 'Put a secret string');
    _;
  }

  constructor(string memory _secret)
    invalidPayment
    payable
  {
    bool reachedCost = msg.value >= 100;
    require(reachedCost, 'Your payment has not reached the cost');

    bool hasSecretInitialValue = bytes(_secret).length != 0;
    if (hasSecretInitialValue) {
      secret = _secret;
    }

    owner = payable(msg.sender);
  }

  function newSecret(string memory _secret) public
    checkOwner('Only owner can update the secret')
    invalidPayment
    checkEmptySecret(_secret)
    payable
  {
    bool reachedCost = msg.value >= 100;
    require(reachedCost, 'Your payment has not reached the cost');

    secret = _secret;
  }

  function getSecret() public
    checkOwner('Only owner can view the secret')
    view returns (string memory)
  {
    return secret;
  }

  function totalSpent() public
    checkOwner('You are not the owner')
    view returns (uint256)
  {
    return address(this).balance;
  }

  function changeOwner(address newOwner) public
    checkOwner('Only owner can set a new owner')
    alreadyOwner(newOwner)
  {
    owner = newOwner;
  }
}
