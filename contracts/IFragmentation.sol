// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;

interface IFragmentation{

  //mapping(address => bool) public isFTToken;
  function isFTToken(address _FTAddr) external returns(bool);
}
