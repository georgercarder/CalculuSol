// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pow.sol";
import "./LookupTables.sol";

library Calculus {

  struct fn {
    fn[] composedWith; // composition member
    Form form; // transcendental, polynomial, etc
    int scalar;
    int[] coefficients;
    fn[] operands;
    BinaryOp op;
    uint one;
  }

  uint constant PI = 3141592653589793238462643383279502884; // to 36 decimal places

  enum Form {BINARYOP, POLYNOMIAL, SIN, COS, EXP, LN} // etc
  enum BinaryOp {NONE, ADD, SUBTRACT, MULTIPLY, DIVIDE}

  // transcendental
  function newFn(Form form, uint one) internal pure returns(fn memory) {
    require(form > Form.POLYNOMIAL, "use newFn(int[]) for POLYNOMIAL");
    fn[] memory blank;
    int[] memory blank_;
    return fn(blank, form, 1, blank_, blank, BinaryOp.NONE, one);
  }

  function newFn(Form form, uint one, int scalar) internal pure returns(fn memory) {
    require(form > Form.POLYNOMIAL, "use newFn(int[]) for POLYNOMIAL");
    fn[] memory blank;
    int[] memory blank_;
    return fn(blank, form, scalar, blank_, blank, BinaryOp.NONE, one);
  }

  // polynomial
  function newFn(int[] memory coefficients, uint one) internal pure returns(fn memory) {
    fn[] memory blank;
    return fn(blank, Form.POLYNOMIAL, 1, coefficients, blank, BinaryOp.NONE, one);
  }

  function newFn(int[] memory coefficients, int scalar, uint one) internal pure returns(fn memory) {
    fn[] memory blank;
    return fn(blank, Form.POLYNOMIAL, scalar, coefficients, blank, BinaryOp.NONE, one);
  }

  // as operation
  function newFn(fn[] memory operands, BinaryOp op) internal pure returns(fn memory) {
    fn[] memory blank;
    int[] memory blank_;
    return fn(blank, Form.BINARYOP, 0, blank_, operands, op, 0); 
  }
  
  function evaluate(fn memory self, int input, uint accuracy, uint[] memory factorialLookupTable) internal pure returns(int) {
    if (self.composedWith.length > 0)
      input = evaluate(self.composedWith[0], input, accuracy, factorialLookupTable);
      (input,) = _normalizeWRTOnes(input, self.composedWith[0].one, 0, self.one);
    if (self.form > Form.POLYNOMIAL) {
      return _evaluateTranscendental(self, input, accuracy, factorialLookupTable);
    } // else form == POLYNOMIAL
    if (self.form == Form.POLYNOMIAL)
      return _evaluatePolynomial(self, input, factorialLookupTable);
    return _evaluateBinaryOperation(self, input, accuracy, factorialLookupTable);
  }

  // evaluates polynomial having rational input and coeffiecients 
  function evaluate(fn memory self, int input, uint[] memory factorialLookupTable) internal pure returns(int) {
    require(self.form == Form.POLYNOMIAL, "form must be polynomial.");
    return _evaluatePolynomial(self, input, factorialLookupTable);
  }

  enum QuotientType {NONE, FACTORIAL, FACTOR}

  function _evaluateTranscendental(fn memory self, int input, uint accuracy, uint[] memory factorialLookupTable) private pure returns(int) {
    int[] memory coefficients = new int[](2*accuracy+1);
    QuotientType qt = QuotientType.NONE;
    uint startIdx;
    uint idxGap=1;
    int unit=1;
    if (self.form < Form.EXP) { // then is sin or cos
      qt = QuotientType.FACTORIAL;
      input = _putInNeighborhoodOfZero(input, self.one);
      accuracy = 2*accuracy; 
      startIdx = (self.form==Form.SIN) ? 1 : 0;
      idxGap=2;
      unit=-1;
    } else if (self.form == Form.EXP) {
      qt = QuotientType.FACTORIAL;
      // it's really lovely the many ways EXP is composed with SIN,COS in both R, C :)
    } else if (self.form == Form.LN) {
      qt = QuotientType.FACTOR; 
      input = input - int(self.one);
      require(Pow.abs(input) < int(self.one), "input out of domain.");
      accuracy = 2*accuracy;
      startIdx = 1;
      idxGap=2;
      unit=-1;
      // TODO update unit test for LN
    }
    int[] memory lookupTable;
    if (qt == QuotientType.FACTORIAL) {
      lookupTable = LookupTables.buildFactorialReciprocalsLookupTable(factorialLookupTable, self.one);
    } else if (qt == QuotientType.FACTOR) {
      lookupTable = LookupTables.buildFactorReciprocalsLookupTable(self.one, accuracy);
    } else {  // qt == QuotientType.NONE
      //  TODO
    }
    { // stack too deep
    uint idx;
    uint n;
    if (startIdx==1) {
      coefficients[idx]=0; 
      idx++;
    }
    for (uint i=startIdx; i<accuracy; i+=idxGap) {
      coefficients[idx] = (unit**n) * lookupTable[i]; 
      n++;
      idx+=idxGap;
    }
    }
    return _evaluatePolynomial(newFn(coefficients, self.scalar, self.one), input, factorialLookupTable);
  }

  function _putInNeighborhoodOfZero(int input, uint one) private pure returns(int ret) {
      uint TwoPiNormalized = 2 * PI * one / (10**36);
      ret = input % int(TwoPiNormalized); // we embrace the periodicity
  }

  // assumes input, and coefficients are rationals Q
  function _evaluatePolynomial(fn memory self, int input, uint[] memory factorialLookupTable) private pure returns(int) {
    int ret;
    uint coefLen = self.coefficients.length;
    for (uint i=0; i<coefLen; i++) {
      ret += self.coefficients[i] * Pow.pow(input, i, self.one, factorialLookupTable);
    }
    ret = ret / int(self.one);
    return self.scalar * ret;
  }

  function _evaluateBinaryOperation(fn memory self, int input, uint accuracy, uint[] memory factorialLookupTable) private pure returns(int) {
    require(self.op > BinaryOp.NONE && self.op <= BinaryOp.DIVIDE, "BinaryOp undefined.");
    int res0 = evaluate(self.operands[0], input, accuracy, factorialLookupTable);
    int res1 = evaluate(self.operands[1], input, accuracy, factorialLookupTable);
    (res0, res1) = _normalizeWRTOnes(res0, self.operands[0].one, res1, self.operands[1].one);
    if (self.op == BinaryOp.ADD) {
      return res0 + res1;
    }
    if (self.op == BinaryOp.SUBTRACT) {
      return res0 - res1;
    }
    if (self.op == BinaryOp.MULTIPLY) {
      return res0 * res1;
    } // else if fn.op == BinaryOp.DIVIDE
    return res0 / res1;
  }

  function _normalizeWRTOnes(int value0, uint one0, int value1, uint one1) private pure returns(int, int) {
    if (one0==one1) return (value0, value1);
    if (one0 < one1) 
      return (int(one1)*value0/int(one0), value1); 
    return (value0, int(one0)*value1/int(one1));
  }

  function compose(fn memory self, fn memory other) internal pure returns(fn memory) {
    self.composedWith = new fn[](1);
    self.composedWith[0] = other; 
    return self;
  }

  function differentiate(fn memory self) internal pure returns(fn memory) {
    fn[] memory operands = new fn[](1);
    bool isInner=true;
    operands[0] = _differentiate(self, !isInner); 
    if (self.composedWith.length > 0) {
      operands = new fn[](2);
      isInner=true;
      operands[1] = _differentiate(self.composedWith[0], isInner);
      return newFn(operands, BinaryOp.MULTIPLY); 
    }
    return operands[0];
  }

  function _differentiate(fn memory self, bool isInner) private pure returns(fn memory) {
    require(!(isInner && self.composedWith.length>0), "composition depth not yet supported.");
    if (self.form > Form.POLYNOMIAL)
      return _differentiateTranscendental(self);
    if (self.form == Form.POLYNOMIAL)
      return _differentiatePolynomial(self);
    return _differentiateBinaryOp(self);
  }

  // FIXME handle LN
  function _differentiateTranscendental(fn memory self) private pure returns(fn memory) {
    // composition is handled by _differentiate
    if (self.form == Form.SIN) {
      self.form = Form.COS;
      return self;
    } else if (self.form == Form.COS) {
      self.scalar = -self.scalar;
      self.form = Form.SIN;
      return self;
    } // ETC
    // case EXP
    return self;
  }

  function _differentiatePolynomial(fn memory self) private pure returns(fn memory) {
    // composition is handled by _differentiate
    uint coefLen = self.coefficients.length;
    int[] memory coefficients = new int[](coefLen-1);
    for (uint i=0; i<coefLen-1; i++) {
      coefficients[i] = self.coefficients[i+1] * int(i+1);
    } 
    return newFn(coefficients, self.scalar, self.one);
  }

  function _differentiateBinaryOp(fn memory self) private pure returns(fn memory) {
    fn[] memory dfs = new fn[](2);
    dfs[0] = differentiate(self.operands[0]);
    dfs[1] = differentiate(self.operands[1]);
    if (self.op < BinaryOp.MULTIPLY) { // +,-
      // d op = op d
      return newFn(dfs, self.op); 
    } 
    fn[] memory factors0 = new fn[](2);
    factors0[0] = self.operands[0];
    factors0[1] = dfs[1]; 
    fn[] memory factors1 = new fn[](2);
    factors1[0] = self.operands[1];
    factors1[1] = dfs[0];
    fn[] memory summands = new fn[](2);
    summands[0] = newFn(factors0, BinaryOp.MULTIPLY);
    summands[1] = newFn(factors1, BinaryOp.MULTIPLY);
    if (self.op == BinaryOp.MULTIPLY) {
      // a*b' + a'*b
      return newFn(summands, BinaryOp.ADD);
    } // self.op == BinaryOp.DIVIDE
    // low * dHigh - high * dLow / (low)^2 :)
    fn[] memory operands = new fn[](2);
    operands[0] = newFn(summands, BinaryOp.SUBTRACT);
    fn[] memory lows = new fn[](2);
    lows[0] = self.operands[1];
    lows[1] = self.operands[1];
    operands[1] = newFn(lows, BinaryOp.MULTIPLY);
    return newFn(operands, BinaryOp.DIVIDE);
  }

  /*
  function integrate(fn self) external returns(fn);
 */

}
