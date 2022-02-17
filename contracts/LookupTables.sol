// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LookupTables {

  function buildFactorialLookupTable(uint n) internal pure returns(uint[] memory) {
    uint[] memory ret = new uint[](n+1);
    ret[0] = 1;
    for (uint i=1; i<=n; i++) {
      ret[i] = i * ret[i-1]; 
    }
    return ret;
  }

  function buildFactorialReciprocalsLookupTable(uint[] memory factorialLookupTable, uint one) internal pure returns(int[] memory ret) {
    ret = new int[](factorialLookupTable.length); 
    uint len = factorialLookupTable.length;
    for (uint i=0; i<len; i++) {
      ret[i] = int(one / factorialLookupTable[i]); // no normalizing by one since factorialLookupTable is not scaled by one
    }
    return ret;
  }

}
