//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Calculus {

  // TODO lookup table of {1/(n!)} for some "big" n (20??) since will be used in _evaluateTranscendental

  // TODO currently only for f: Z -> Z integers, extend to give f: Q -> Q the rationals

  struct fn {
    fn[] composedWith; // composition member
    Form form; // transcendental, polynomial, etc
    int polarity;
    int[] coefficients;
  }

  enum Form {POLYNOMIAL, SIN, COS, EXP} // etc

  function newFn(Form form) internal pure returns(fn memory) {
    require(form > Form.POLYNOMIAL, "use newFn(int[]) for POLYNOMIAL");
    fn[] memory composedWith;
    int[] memory coefficients;
    fn memory f = fn(composedWith, form, 1, coefficients);
    return f;
  }

  function newFn(int[] memory coefficients) internal pure returns(fn memory) {
    fn[] memory composedWith;
    fn memory f = fn(composedWith, Form.POLYNOMIAL, 1, coefficients);
    return f;
  }

  function evaluate(fn memory self, int input, uint accuracy, uint[] calldata factorialLookupTable) internal returns(int) {
    if (self.composedWith.length > 0)
      input = evaluate(self.composedWith[0], input, accuracy, factorialLookupTable);
    if (self.form > Form.POLYNOMIAL) {
      return _evaluateTranscendental(self, input, accuracy, factorialLookupTable);
    } // else form == POLYNOMIAL
    return _evaluatePolynomial(self, input);
  }

  function evaluate(fn memory self, int input) internal pure returns(int) {
    require(self.form == Form.POLYNOMIAL, "form must be polynomial.");
    return _evaluatePolynomial(self, input);
  }

  function _evaluateTranscendental(fn memory self, int input, uint accuracy, uint[] calldata factorialLookupTable) internal returns(int) {
    // TODO use Maclaurin series
    // TODO acknowledge sin, cos, etc.
    // TODO acknowledge polarity
  }

  function _evaluatePolynomial(fn memory self, int input) internal pure returns(int) {
    int ret;
    uint coefLen = self.coefficients.length;
    for (uint i=0; i<coefLen; i++) {
      ret += self.coefficients[i] * (input ** i);
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

  function _derive(fn memory self, bool isInner) internal pure returns(fn memory) {
    require(!(isInner && self.composedWith.length>0), "composition depth not yet supported.");
    if (self.form > Form.POLYNOMIAL) {
      return _deriveTranscendental(self);
    } // else form == POLYNOMIAL
    return _derivePolynomial(self);
  }

  function _deriveTranscendental(fn memory self) internal pure returns(fn memory) {
    // composition is handled by _derive
    if (self.form == Form.SIN) {
      self.form = Form.COS;
      return self;
    } else if (self.form == Form.COS) {
      self.polarity = -self.polarity;
      self.form = Form.SIN;
      return self;
    } // ETC TODO
    // case EXP
    return self;
  }

  function _derivePolynomial(fn memory self) internal pure returns(fn memory) {
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
