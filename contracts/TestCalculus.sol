// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Calculus.sol";

contract TestCalculus {

  struct strippedFn {
    Calculus.Form form; // transcendental, polynomial, etc
    int scalar;
    int[] coefficients;
    uint one;
  }

  function testPolynomial(int[] calldata coefficients, uint one) external pure returns(strippedFn memory) {
    Calculus.fn memory f = Calculus.newFn(coefficients, one);
    return strippedFn(f.form, f.scalar, f.coefficients, f.one);
  }

  function testPolynomialEvaluation(int[] calldata coefficients, int input, uint one) external pure returns(int) {
    Calculus.fn memory f = Calculus.newFn(coefficients, one);
    uint[] memory ft = LookupTables.buildFactorialLookupTable(coefficients.length);
    return Calculus.evaluate(f, input, 0, ft); // accuracy=0 for polynomial
  }

  function testPolynomialDifferentiation(int[] calldata coefficients, uint one) external pure returns(strippedFn memory) {
    Calculus.fn memory f = Calculus.newFn(coefficients, one);
    // FIXME after operands refactor
    //Calculus.fn[] memory df = Calculus.differentiate(f);
    //return strippedFn(df[0].form, df[0].scalar, df[0].coefficients, df[0].one);
  }

  function testTrigDifferentiation(Calculus.Form form, uint one, int scalar, bool differentiate) external pure returns(strippedFn memory) {
    Calculus.fn memory f = Calculus.newFn(form, one, scalar); 
    if (!differentiate) return strippedFn(f.form, f.scalar, f.coefficients, f.one);
    // FIXME after operands refactor
    //Calculus.fn[] memory df = Calculus.differentiate(f);
    //return strippedFn(df[0].form, df[0].scalar, df[0].coefficients, df[0].one);
  }

  function testTranscendentalEvaluation(Calculus.Form form, uint one, int scalar, int input, uint accuracy) external pure returns(int) {
    Calculus.fn memory f = Calculus.newFn(form, one, scalar); 
    uint[] memory ft = LookupTables.buildFactorialLookupTable(2*accuracy);
    return Calculus.evaluate(f, input, accuracy, ft);
  }

}
