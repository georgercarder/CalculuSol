// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pow.sol";
import "./LookupTables.sol";

contract TestPow {

  function testFactorialLookupTable(uint number) public pure returns(uint[] memory) {
    uint[] memory ft = LookupTables.buildFactorialLookupTable(number);
    return ft;
  }

  function testPowInteger(int base, uint power, int one, uint factorialLookupBound) public pure returns(int) {
    uint[] memory factorialLookupTable = LookupTables.buildFactorialLookupTable(factorialLookupBound);
    return Pow.pow(base, power, one, factorialLookupTable);
  }

  function testPowIntegerGas(int base, uint power, int one, uint factorialLookupBound) public {
    uint[] memory factorialLookupTable = LookupTables.buildFactorialLookupTable(factorialLookupBound);
    require(Pow.pow(base, power, one, factorialLookupTable)!=0, "trivial check");
  }

}
