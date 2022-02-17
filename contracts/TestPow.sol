//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Pow.sol";

contract TestPow {

  function testFactorialLookupTable(uint number) public pure returns(uint[] memory) {
    uint[] memory ft = Pow.buildFactorialLookupTable(number);
    return ft;
  }

  function testPowInteger(int base, uint power, int one, uint factorialLookupBound) public pure returns(int) {
    uint[] memory factorialLookupTable = Pow.buildFactorialLookupTable(factorialLookupBound);
    return Pow.pow(base, power, one, factorialLookupTable);
  }

}
