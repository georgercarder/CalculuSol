// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Calculus.sol";

contract TestCalculus {

  struct strippedFn {
    Calculus.Form form; // transcendental, polynomial, etc
    int polarity;
    int[] coefficients;
  }

  function testPolynomial(int[] calldata coefficients) external pure returns(strippedFn memory) {
    Calculus.fn memory f = Calculus.newFn(coefficients);
    return strippedFn(f.form, f.polarity, f.coefficients);
  }

  function testPolynomialEvaluation(int[] calldata coefficients, int input, int one) external pure returns(int) {
    Calculus.fn memory f = Calculus.newFn(coefficients);
    uint[] memory ft = LookupTables.buildFactorialLookupTable(coefficients.length);
    return Calculus.evaluate(f, input, one, 0, ft); // accuracy=0 for polynomial
  }

  function testPolynomialDifferentiation(int[] calldata coefficients) external pure returns(strippedFn memory) {
    Calculus.fn memory f = Calculus.newFn(coefficients);
    Calculus.fn[] memory df = Calculus.differentiate(f);
    return strippedFn(df[0].form, df[0].polarity, df[0].coefficients);
  }

}
