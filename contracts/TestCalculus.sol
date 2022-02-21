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

  function testDEBUG(uint one0, int[] calldata coefficients0, Calculus.Form f1, uint one1, int scalar1, int input, uint accuracy) external pure returns(strippedFn memory) { 

    Calculus.fn memory f = Calculus.newFn(coefficients0, one0);
    Calculus.fn memory g = Calculus.newFn(f1, one1, scalar1); 

    Calculus.fn memory fg = Calculus.compose(f, g);
  
    Calculus.fn memory dfg = Calculus.differentiate(fg);
    return strippedFn(dfg.form, dfg.op, dfg.scalar, dfg.coefficients, dfg.one);
  }


  // FIXME this test is showing there are many bugs wrt composition.. must fix
  function testComposition(uint one0, int[] calldata coefficients0, Calculus.Form f1, uint one1, int scalar1, int input, uint accuracy) external pure returns(int[] memory) {
    Calculus.fn memory f = Calculus.newFn(coefficients0, one0);
    Calculus.fn memory g = Calculus.newFn(f1, one1, scalar1); 

    Calculus.fn memory fg = Calculus.compose(f, g);
    //Calculus.fn memory gf = Calculus.compose(g, f);

    Calculus.fn memory dfg = Calculus.differentiate(fg);
    // FIXME this alters ret[0] below.. does differentiate write to "self"?

    // debugging
    /*require(dfg.form==Calculus.Form.BINARYOP, "debug");
    require(dfg.op>Calculus.BinaryOp.NONE && dfg.op<=Calculus.BinaryOp.DIVIDE, "debug");
    require(dfg.composedWith.length==0, "debug");
    require(dfg.op==Calculus.BinaryOp.MULTIPLY, "debug");
    */
    // end debugging

    //Calculus.fn memory dgf = Calculus.differentiate(gf);

    uint[] memory frt = LookupTables.buildFactorialReciprocalsLookupTable(2*accuracy);

    int[] memory ret = new int[](4);

    { // stack too deep
    ret[0] = Calculus.evaluate(fg, input, accuracy, frt);
    }
    { // stack too deep
    //ret[1] = Calculus.evaluate(gf, input, accuracy, frt);
    }
    
    { // stack too deep
    //ret[2] = Calculus.evaluate(dfg, input, accuracy, frt);
    }
    /*
    { // stack too deep
    ret[3] = Calculus.evaluate(dgf, input, accuracy, frt);
    }
    */
    return ret;
  }

}
