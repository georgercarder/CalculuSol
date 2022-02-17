const { expect } = require("chai");
const { ethers } = require("hardhat");

function bn(number) {
  return new ethers.BigNumber.from(number);
}

describe("TestCalculus", function () {
  it("checks correctness of Calculus library wrt polynomials", async function () {
    const TestCalculus = await ethers.getContractFactory("TestCalculus");
    const testCalculus = await TestCalculus.deploy();
    await testCalculus.deployed();
     
    let coefficients = [1, 20, 3, 40];
    let one = 1;
    let res = await testCalculus.testPolynomial(coefficients, one);
    let expected = [0, bn(1), bn(1), bn(20), bn(3), bn(40)];
    expect(res.form).to.equal(expected[0]);
    expect(res.polarity).to.equal(expected[1]);
    for (let i=0; i<res.coefficients.length; i++) {
      expect(res.coefficients[i]).to.equal(expected[i+2]);
    }

    let input = 2; // input is an integer
    let evaluatedPolynomial = bn(0);//bn(coefficients[0]);
    for (let i=0; i<coefficients.length; i++) {
      evaluatedPolynomial = evaluatedPolynomial.add(bn(coefficients[i]).mul(bn(input).pow(bn(i))))
    }
    expect(await testCalculus.testPolynomialEvaluation(coefficients, input, one)).to.equal(evaluatedPolynomial);

    input = 25777000; // input is a rational
    // 2.5777
    one = 10000000;
    for (let i=0; i<coefficients.length; i++) {
      coefficients[i] = coefficients[i]*one;
    }
    expect(await testCalculus.testPolynomialEvaluation(coefficients, input, one)).to.equal(bn(7575925356)); // "close" according to wolfram alpha 757.593
    
    // check differentiation
    /*expected = [0, bn(1), bn(20), bn(6), bn(120)];
    res = await testCalculus.testPolynomialDifferentiation(coefficients, one);
    expect(res.form).to.equal(expected[0]);
    expect(res.polarity).to.equal(expected[1]);
    for (let i=0; i<res.coefficients.length; i++) {
      expect(res.coefficients[i]).to.equal(expected[i+2]);
    }
    */
  });
});
