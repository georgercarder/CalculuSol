// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pow.sol";
import "./LookupTables.sol";

library Calculus {

  // TODO currently coefficients are assumed to be integers Z, while the indeterminate is from the rationals Q, so need to update so that coefficients are also from Q

  struct fn {
    fn[] composedWith; // composition member
    Form form; // transcendental, polynomial, etc
    int polarity;
    int[] coefficients;
    uint one;
  }

  uint constant PI = 3141592653589793238462643383279502884; // to 36 decimal places

  enum Form {POLYNOMIAL, SIN, COS, EXP, LN} // etc

  // transcendental
  function newFn(Form form, uint one) internal pure returns(fn memory) {
    require(form > Form.POLYNOMIAL, "use newFn(int[]) for POLYNOMIAL");
    fn[] memory composedWith;
    int[] memory coefficients;
    return fn(composedWith, form, 1, coefficients, one);
  }

  function newFn(Form form, uint one, int polarity) internal pure returns(fn memory) {
    require(form > Form.POLYNOMIAL, "use newFn(int[]) for POLYNOMIAL");
    fn[] memory composedWith;
    int[] memory coefficients;
    return fn(composedWith, form, polarity, coefficients, one);
  }

  // polynomial
  function newFn(int[] memory coefficients, uint one) internal pure returns(fn memory) {
    fn[] memory composedWith;
    return fn(composedWith, Form.POLYNOMIAL, 1, coefficients, one);
  }

  function newFn(int[] memory coefficients, int polarity, uint one) internal pure returns(fn memory) {
    fn[] memory composedWith;
    return fn(composedWith, Form.POLYNOMIAL, polarity, coefficients, one);
  }

  function evaluate(fn memory self, int input, uint accuracy, uint[] memory factorialLookupTable) internal pure returns(int) {
    if (self.composedWith.length > 0)
      input = evaluate(self.composedWith[0], input, accuracy, factorialLookupTable);
    if (self.form > Form.POLYNOMIAL) {
      return _evaluateTranscendental(self, input, accuracy, factorialLookupTable);
    } // else form == POLYNOMIAL
    return _evaluatePolynomial(self, input, factorialLookupTable);
  }

  // evaluates polynomial having integer coefficients and rational input
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
    if (self.form != Form.EXP) { // then is sin or cos
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
    return _evaluatePolynomial(newFn(coefficients, self.polarity, self.one), input, factorialLookupTable);
  }

  function _putInNeighborhoodOfZero(int input, uint one) private pure returns(int ret) {
      uint TwoPiNormalized = 2 * PI * one / (10**36);
      ret = input % int(TwoPiNormalized); // we embrace the periodicity
  }

  // currently assumes input is a rational and coefficients is an integer
  function _evaluatePolynomial(fn memory self, int input, uint[] memory factorialLookupTable) private pure returns(int) {
    int ret;
    uint coefLen = self.coefficients.length;
    for (uint i=0; i<coefLen; i++) {
      ret += self.coefficients[i] * Pow.pow(input, i, self.one, factorialLookupTable);
    }
    ret = ret / int(self.one);
    return self.polarity * ret;
  }

  function compose(fn memory self, fn memory other) internal pure returns(fn memory) {
    self.composedWith = new fn[](1);
    self.composedWith[0] = other; 
    return self;
  }

  function differentiate(fn memory self) internal pure returns(fn[] memory factors) {
    factors = new fn[](1);
    bool isInner=true;
    if (self.composedWith.length > 0) {
      factors = new fn[](2);
      isInner=true;
      factors[1] = _differentiate(self.composedWith[0], isInner);
    }
    factors[0] = _differentiate(self, !isInner); 
  }

  function _differentiate(fn memory self, bool isInner) private pure returns(fn memory) {
    require(!(isInner && self.composedWith.length>0), "composition depth not yet supported.");
    if (self.form > Form.POLYNOMIAL) {
      return _differentiateTranscendental(self);
    } // else form == POLYNOMIAL
    return _differentiatePolynomial(self);
  }

  // FIXME handle LN
  function _differentiateTranscendental(fn memory self) private pure returns(fn memory) {
    // composition is handled by _differentiate
    if (self.form == Form.SIN) {
      self.form = Form.COS;
      return self;
    } else if (self.form == Form.COS) {
      self.polarity = -self.polarity;
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
    return newFn(coefficients, self.one);
  }

  /*
  function integrate(fn self) external returns(fn);
 */

}
