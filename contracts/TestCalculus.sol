// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Calculus.sol";

contract TestCalculus {

  struct strippedFn {
    Calculus.Form form; // transcendental, polynomial, etc
    Calculus.BinaryOp op;
    int scalar;
    int[] coefficients;
    uint one;
  }

  function testPolynomial(int[] calldata coefficients, uint one) external pure returns(strippedFn memory) {
    Calculus.fn memory f = Calculus.newFn(coefficients, one);
    return strippedFn(f.form, f.op, f.scalar, f.coefficients, f.one);
  }

  function testPolynomialEvaluation(int[] calldata coefficients, int input, uint one) external pure returns(int) {
    Calculus.fn memory f = Calculus.newFn(coefficients, one);
    return Calculus.evaluate(f, input);
  }

  function testPolynomialDifferentiation(int[] calldata coefficients, uint one) external pure returns(strippedFn memory) {
    Calculus.fn memory f = Calculus.newFn(coefficients, one);
    Calculus.fn memory df = Calculus.differentiate(f);
    return strippedFn(df.form, df.op, df.scalar, df.coefficients, df.one);
  }

  function testTrigDifferentiation(Calculus.Form form, uint one, int scalar, bool differentiate) external pure returns(strippedFn memory) {
    Calculus.fn memory f = Calculus.newFn(form, one, scalar); 
    if (!differentiate) return strippedFn(f.form, f.op, f.scalar, f.coefficients, f.one);
    Calculus.fn memory df = Calculus.differentiate(f);
    return strippedFn(df.form, df.op, df.scalar, df.coefficients, df.one);
  }

  function testTranscendentalEvaluation(Calculus.Form form, uint one, int scalar, int input, uint accuracy) external pure returns(int) {
    Calculus.fn memory f = Calculus.newFn(form, one, scalar); 
    uint[] memory frt = LookupTables.buildFactorialReciprocalsLookupTable(2*accuracy);
    return Calculus.evaluate(f, input, accuracy, frt);
  }

  function testComposition(uint[] calldata ones, int[][] calldata coefficients, int[] calldata scalars, int input, uint accuracy) external pure returns(int) {
    Calculus.fn memory f = Calculus.newFn(coefficients[0], scalars[0], ones[0]);
    Calculus.fn memory g = Calculus.newFn(coefficients[1], scalars[1], ones[1]);
    Calculus.fn memory fog = Calculus.compose(f, g);
    uint[] memory frt = LookupTables.buildFactorialReciprocalsLookupTable(2*accuracy);
    return Calculus.evaluate(fog, input, accuracy, frt);
  }

  function testDifferentiateComposition(uint[] calldata ones, int[][] calldata coefficients, int[] calldata scalars, int input, uint accuracy) external pure returns(int) {
    Calculus.fn memory f = Calculus.newFn(coefficients[0], scalars[0], ones[0]);
    Calculus.fn memory g = Calculus.newFn(coefficients[1], scalars[1], ones[1]);
    Calculus.fn memory fog = Calculus.compose(f, g);
    uint[] memory frt = LookupTables.buildFactorialReciprocalsLookupTable(2*accuracy);
    Calculus.fn memory dfog = Calculus.differentiate(fog);
    return Calculus.evaluate(dfog, input, accuracy, frt);
  }

}
