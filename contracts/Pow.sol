// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Pow is b^n approximation where b is a rational number and n is a natural number
library Pow {

  function abs(int x) internal pure returns(int) {
    return (x>0) ? x : -x;
  }

  function pow(int base, uint power, int one, uint[] memory factorialLookupTable) internal pure returns(int ret) {
    require(factorialLookupTable.length+1 >= power, "factorialLookupTable is lacking."); // TODO double check this indexing wrt ( n k ) (choose)
    int sign = (base > int(0)) ? int(1) : int(-1);
    int absBase = abs(base);
    int integer = absBase / one; 
    int fraction = absBase % one;
    int firstTermOfBinomialExpansion = _sign(sign, power) * (integer ** power) * one;
    ret += firstTermOfBinomialExpansion;
    if (fraction != 0) ret += _lesserTermsOfBinomialExpansion(sign, integer, fraction, power, one, factorialLookupTable);
  }

  // sum (0,n) i : (n i) * a^(n-i) * b^i

  function _lesserTermsOfBinomialExpansion(int sign, int absInteger, int absFraction, uint power, int one, uint[] memory factorialLookupTable) private pure returns(int ret) {
    int pf; // powFraction
    for (uint i=1; i<=power; i++) {
      pf = _powFraction(absFraction, i, one); // this has factor of one
      if (pf == 0) {
        continue;
      }
      ret += int(nChooseK(power, i, factorialLookupTable)) * _sign(sign, power-i)*(absInteger**(power-i)) * _sign(sign, power-i)*pf;
    }
  }

  function nChooseK(uint n, uint k, uint[] memory factorialLookupTable) internal pure returns(uint ret) {
    // n!/(k!*(n-k)!)
    return factorialLookupTable[n] / (factorialLookupTable[k] * factorialLookupTable[n-k]);
  }

  function _powFraction(int absBase, uint power, int one) private pure returns(int) {
    if (power == 1) return absBase;
    return absBase * _powFraction(absBase, power-1, one) / one; 
  }

  function _sign(int sign, uint power) private pure returns(int) {
    if (sign >0) {
      return int(1);
    }
    return (power%2==0) ? int(1) : int(-1);
  }

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

}
