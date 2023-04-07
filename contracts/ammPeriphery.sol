// SPDX-License-Identifier: MIT

import "./IAMM.sol";

pragma solidity ^0.8.9;


contract Router{
    IAMM amm;
    uint constant ONE_ETH = 10 ** 18;
    constructor(address _amm){
        amm = IAMM(_amm);

    }
    function getTokenPrice(address _tokenA, address _tokenB) public view returns(uint reserveA,uint reserveB, uint one_tokenA_price,uint one_tokenB_price)
    {
        address lptokenAddr = amm.getLptoken(_tokenA,_tokenB);
        reserveA = amm.getReserve(lptokenAddr, _tokenA);
        reserveB = amm.getReserve(lptokenAddr,_tokenB);

        one_tokenA_price = reserveB * ONE_ETH / reserveA;
        one_tokenB_price = reserveA * ONE_ETH / reserveB;
            
    }

    function cacalTokenOutAmount(address _tokenIn, address _tokenOut, uint _tokenInAmount) public view returns(uint tokenOutAmount)
    {
        address lptokenAddr = amm.getLptoken(_tokenIn,_tokenOut);
        uint reserveIn = amm.getReserve(lptokenAddr, _tokenIn);
        uint reserveOut = amm.getReserve(lptokenAddr,_tokenOut);

        tokenOutAmount = (reserveOut * _tokenInAmount) / (reserveIn + _tokenInAmount);
    }

    function cacalLpTokenAddAmount(address _tokenA, address _tokenB, uint _amountA) public view returns(uint _amountB)
    {
        address lptokenAddr = amm.getLptoken(_tokenA,_tokenB);
        _amountB = amm.getReserve(lptokenAddr,_tokenB) * _amountA / amm.getReserve(lptokenAddr, _tokenA);
    }

    
}
