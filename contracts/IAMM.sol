// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAMM {
    function getLptoken(address _tokenA, address _tokenB) external view returns(address);

    function getReserve(address _lpTokenAddr, address _tokenAddr) external view returns(uint);

}
