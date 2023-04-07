// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;

interface ICalculate{

    function calculateRewardTokenAmount(uint _reserver, uint _addAmount) external pure returns (uint output);
}
