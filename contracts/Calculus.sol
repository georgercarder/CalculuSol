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
  }

  uint constant PI = 3141592653589793238462643383279502884; // to 36 decimal places

  enum Form {POLYNOMIAL, SIN, COS, EXP} // etc

  function newFn(Form form) internal pure returns(fn memory) {
    require(form > Form.POLYNOMIAL, "use newFn(int[]) for POLYNOMIAL");
    fn[] memory composedWith;
    int[] memory coefficients;
    return fn(composedWith, form, 1, coefficients);
  }

  function newFn(int[] memory coefficients) internal pure returns(fn memory) {
    fn[] memory composedWith;
    return fn(composedWith, Form.POLYNOMIAL, 1, coefficients);
  }

  function newFn(int[] memory coefficients, int polarity) internal pure returns(fn memory) {
    fn[] memory composedWith;
    return fn(composedWith, Form.POLYNOMIAL, polarity, coefficients);
  }

  function evaluate(fn memory self, int input, int one, uint accuracy, uint[] memory factorialLookupTable) internal returns(int) {
    if (self.composedWith.length > 0)
      input = evaluate(self.composedWith[0], input, one, accuracy, factorialLookupTable);
    if (self.form > Form.POLYNOMIAL) {
      return _evaluateTranscendental(self, input, one, accuracy, factorialLookupTable);
    } // else form == POLYNOMIAL
    return _evaluatePolynomial(self, input, one, factorialLookupTable);
  }

  // evaluates polynomial having integer coefficients and rational input
  function evaluate(fn memory self, int input, int one, uint[] memory factorialLookupTable) internal pure returns(int) {
    require(self.form == Form.POLYNOMIAL, "form must be polynomial.");
    return _evaluatePolynomial(self, input, one, factorialLookupTable);
  }

  function _evaluateTranscendental(fn memory self, int input, int one, uint accuracy, uint[] memory factorialLookupTable) private pure returns(int) {
    int[] memory coefficients = new int[](accuracy);
    uint startIdx;
    uint idxGap=1;
    int unit=1;
    if (self.form != Form.EXP) { // then is sin or cos
      uint piNormalized = PI * uint(one) / (10**36);
      input = (input % int(piNormalized)) * one; // we embrace the periodicity
      accuracy = 2*accuracy; 
      startIdx = (self.form==Form.SIN) ? 1 : 0;
      idxGap=2;
      unit=-1;
    } /* else if (self.form == Form.EXP) {
      unit=1;
    }*/ // it's really lovely the many ways EXP is composed with SIN,COS in both R, C :)
    int[] memory factorialReciprocalsLookupTable = LookupTables.buildFactorialReciprocalsLookupTable(factorialLookupTable, uint(one));
    uint idx;
    for (uint i=startIdx; i<accuracy; i+=idxGap) {
      coefficients[idx] = (unit**i) * factorialReciprocalsLookupTable[i]; 
      idx++;
    }
    // FIXME.. think this step is broken until update whole library to support coefficients in Q
    return _evaluatePolynomial(newFn(coefficients, self.polarity), input, one, factorialLookupTable);
  }

  // currently assumes input is a rational and coefficients is an integer
  function _evaluatePolynomial(fn memory self, int input, int one, uint[] memory factorialLookupTable) private pure returns(int) {
    int ret;
    uint coefLen = self.coefficients.length;
    for (uint i=0; i<coefLen; i++) {
      ret += self.coefficients[i] * Pow.pow(input, i, one, factorialLookupTable) / one;
    }
    return self.polarity * ret;
  }

  function compose(fn memory self, fn memory other) internal pure returns(fn memory) {
    self.composedWith = new fn[](1);
    self.composedWith[0] = other; 
    return self;
  }

  function derive(fn memory self) internal pure returns(fn[] memory factors) {
    factors = new fn[](1);
    bool isInner=true;
    if (self.composedWith.length > 0) {
      factors = new fn[](2);
      isInner=true;
      factors[1] = _derive(self.composedWith[0], isInner);
    }
    factors[0] = _derive(self, !isInner); 
  }

  function _derive(fn memory self, bool isInner) private pure returns(fn memory) {
    require(!(isInner && self.composedWith.length>0), "composition depth not yet supported.");
    if (self.form > Form.POLYNOMIAL) {
      return _deriveTranscendental(self);
    } // else form == POLYNOMIAL
    return _derivePolynomial(self);
  }

  function _deriveTranscendental(fn memory self) private pure returns(fn memory) {
    // composition is handled by _derive
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

  function _derivePolynomial(fn memory self) private pure returns(fn memory) {
    // composition is handled by _derive
    uint coefLen = self.coefficients.length;
    int[] memory coefficients = new int[](coefLen-1);
    for (uint i=0; i<coefLen-1; i++) {
      coefficients[i] = self.coefficients[i+1] * int(i);
    } 
    return newFn(coefficients);
  }

  /*
  function integrate(fn self) external returns(fn);
 */

}
