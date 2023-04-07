// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;

contract FTCalculate
{   
    mapping(address => uint) public FTReserve;

    uint constant ONE_ETH = 10 **18;
    
    function _updateFTReserve(address _FTAddr,uint _amount) internal returns(uint)
    {
        FTReserve[_FTAddr] += _amount;
        return FTReserve[_FTAddr];
    }

 

    //少于10个是10倍，超过10小于30是8，30-100是5，100-300是4，300 -1000 是3，1000到3000 是2
    
  uint constant a = 10000 * ONE_ETH; 
  uint constant b = 30000 * ONE_ETH; 
  uint constant c = 100000 * ONE_ETH; 
  uint constant d = 300000 * ONE_ETH; 
  uint constant e = 1000000 * ONE_ETH;
  uint constant f = 3000000 * ONE_ETH;
  function getValue(uint input) internal pure returns (uint output){ 
    if (input <= a) { 
      output = input * 10; 
    }
    else if (input > a && input <= b) {
          output = a * 10 + (input - a) * 8; 
    }
    else if (input > b && input <= c) {
          output = a * 10 + (b - a) * 8 + (input - b) * 5;
    }
    else if (input > c && input <= d) { 
      output = a * 10 + (b - a) * 8 + (c - b) * 5 + (input - c) * 4;
    }
    else if(input > d && input <= e){
      output = a * 10 + (b - a) * 8 + (c - b) * 5 + (d - c) * 4 + (e - d) * 3;
    }
    else if(input > e && input <= f){
        output = a * 10 + (b - a) * 8 + (c - b) * 5 + (d - c) * 4 + (e - d) * 3 + (f - e) * 2;
    }
    else {
        output = a * 10 + (b - a) * 8 + (c - b) * 5 + (d - c) * 4 + (e - d) * 3 + (f - e) * 2 + (input - f);
    }
    return output;
  }

  function calculateRewardTokenAmount(uint _reserver, uint _addAmount) public pure returns (uint output){
      output = getValue(_reserver + _addAmount) - getValue(_reserver);
  }

  function getRewardAndUpdate(address _FTAddr ,uint _reserver, uint _addAmount) public returns(uint)
  {
      
      _updateFTReserve(_FTAddr, _addAmount);
      return  calculateRewardTokenAmount(_reserver,_addAmount);
  }


}
