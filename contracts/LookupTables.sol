// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LookupTables {

  uint constant public one = 10**18;

  function buildFactorReciprocalsLookupTable(uint len) internal pure returns(uint[] memory ret) {
    ret = new uint[](len); 
    ret[0] = one;
    for (uint i=1; i<len; i++) {
      ret[i] = one / i;
    }
    return ret;
  }

  function buildFactorialReciprocalsLookupTable(uint len) internal pure returns(uint[] memory ret) {
    ret = new uint[](len); 
    uint last = 1;
    uint factorial;
    ret[0] = one;
    for (uint i=1; i<len; i++) {
      factorial = last * i;
      ret[i] = one / factorial;
      last = factorial;
    }
    return ret;
  }

}
