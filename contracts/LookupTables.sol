// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LookupTables {

  function buildFactorialLookupTable(uint n) internal pure returns(uint[] memory) {
    require(n>1, "n<=1.");
    uint[] memory ret = new uint[](n+1);
    ret[0] = 1;
    ret[1] = 1;
    for (uint i=2; i<=n; i++) {
      ret[i] = i * ret[i-1]; 
    }
    return ret;
  }

  function buildFactorialReciprocalsLookupTable(uint[] memory factorialLookupTable, uint one) internal pure returns(uint[] memory ret) {
    ret = new uint[](factorialLookupTable.length); 
    uint len = factorialLookupTable.length;
    for (uint i=0; i<len; i++) {
      ret[i] = one / factorialLookupTable[i]; // no normalizing by one since factorialLookupTable is not scaled by one
    }
    return ret;
  }

}
