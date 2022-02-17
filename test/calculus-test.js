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

    // polynomials
     
    let coefficients = [1, 20, 3, 40];
    let one = 1;
    let res = await testCalculus.testPolynomial(coefficients, one);
    let expected = [0, bn(1), bn(1), bn(20), bn(3), bn(40), one];
    expect(res.form).to.equal(expected[0]);
    expect(res.polarity).to.equal(expected[1]);
    for (let i=0; i<res.coefficients.length-1; i++) {
      expect(res.coefficients[i]).to.equal(expected[i+2]);
    }
    expect(res.one).to.equal(expected[expected.length-1]);

    let input = 2; // input is an integer
    let evaluatedPolynomial = bn(0);//bn(coefficients[0]);
    for (let i=0; i<coefficients.length; i++) {
      evaluatedPolynomial = evaluatedPolynomial.add(bn(coefficients[i]).mul(bn(input).pow(bn(i))))
    }
    expect(await testCalculus.testPolynomialEvaluation(coefficients, input, one)).to.equal(evaluatedPolynomial);

    input = 25777000; // input is a rational
    // 2.5777
    one = bn(10000000);
    for (let i=0; i<coefficients.length; i++) {
      coefficients[i] = bn(coefficients[i]).mul(one);
    }
    expect(await testCalculus.testPolynomialEvaluation(coefficients, input, one)).to.equal(bn(7575925356)); // "close" according to wolfram alpha 757.593
    
    // check differentiation
    expected = [0, bn(1), bn(20), bn(6), bn(120), one];
    for (let i=2; i<expected.length-1; i++) {
      expected[i] = expected[i].mul(one);
    }

    res = await testCalculus.testPolynomialDifferentiation(coefficients, one);
    expect(res.form).to.equal(expected[0]);
    expect(res.polarity).to.equal(expected[1]);
    for (let i=0; i<res.coefficients.length-1; i++) {
      expect(res.coefficients[i]).to.equal(expected[i+2]);
    }
    expect(res.one).to.equal(expected[expected.length-1]);

    // transcendentals

    let FORM = {POLYNOMIAL:0, SIN:1, COS:2, EXP:3} // etc
    let polarity = 1;
    let differentiate = false;

    res = await testCalculus.testTrigDifferentiation(FORM.SIN, one, polarity, differentiate);
    expect(res.form).to.equal(FORM.SIN);
    expect(res.polarity).to.equal(polarity);
    expect(res.one).to.equal(one);

    // differentiation ensuring sin -> cos -> -sin -> -cos ~ Z_4
    differentiate = true;
    res = await testCalculus.testTrigDifferentiation(FORM.SIN, one, polarity, differentiate);
    expect(res.form).to.equal(FORM.COS);
    expect(res.polarity).to.equal(polarity);
    expect(res.one).to.equal(one);

    res = await testCalculus.testTrigDifferentiation(FORM.COS, one, polarity, differentiate);
    expect(res.form).to.equal(FORM.SIN);
    expect(res.polarity).to.equal(-polarity);
    expect(res.one).to.equal(one);

    res = await testCalculus.testTrigDifferentiation(FORM.SIN, one, -polarity, differentiate);
    expect(res.form).to.equal(FORM.COS);
    expect(res.polarity).to.equal(-polarity);
    expect(res.one).to.equal(one);

    res = await testCalculus.testTrigDifferentiation(FORM.COS, one, -polarity, differentiate);
    expect(res.form).to.equal(FORM.SIN);
    expect(res.polarity).to.equal(polarity);
    expect(res.one).to.equal(one);

    one = bn(10).pow(18)
    // evaluate some values
    let piString = '3141592653589793238462643383279502884';
    let pi = bn(piString).mul(one).div(bn(10).pow(36));
    input = 0;
    let accuracy = 12; 
    res = await testCalculus.testTranscendentalEvaluation(FORM.SIN, one, polarity, input, accuracy);
    expect(res).to.equal(0); // sanity
    input = pi;
    res = await testCalculus.testTranscendentalEvaluation(FORM.SIN, one, polarity, input, accuracy);
    expect(res).to.equal(-32594034); // sanity ("close" to zero ) // -0.000000000032594034    
    input = 0;
    res = await testCalculus.testTranscendentalEvaluation(FORM.COS, one, polarity, input, accuracy);
    expect(res).to.equal(one); // sanity
    input = pi;
    res = await testCalculus.testTranscendentalEvaluation(FORM.COS, one, polarity, input, accuracy);
    expect(res).to.equal(bn("-1000000003423230545")); // sanity ("close" to -1)
    let piHalves = bn(piString).div(2).mul(one).div(bn(10).pow(36));
    let threePiHalves = bn(piString).mul(3).div(2).mul(one).div(bn(10).pow(36));
    input = piHalves;
    res = await testCalculus.testTranscendentalEvaluation(FORM.SIN, one, polarity, input, accuracy);
    expect(res).to.equal(bn("1000000000000000166")); // sanity ("close" to one)
    input = threePiHalves; 

    res = await testCalculus.testTranscendentalEvaluation(FORM.SIN, one, polarity, input, accuracy);
    expect(res).to.equal("-1000001333538651278"); // sanity ("close" to -1)
    //                     -682941969615792847 513603717600817265

    input = piHalves;
    res = await testCalculus.testTranscendentalEvaluation(FORM.COS, one, polarity, input, accuracy);
    expect(res).to.equal(-3598); // sanity ("close" to zero)
    
    input = threePiHalves; 
    res = await testCalculus.testTranscendentalEvaluation(FORM.COS, one, polarity, input, accuracy);
    expect(res).to.equal("-11224909331762"); // sanity ("close" to 0) //  -0.000011224909331762
    
    // TODO find methods to get better accuracy

    // TODO evaluate more values pi/2 pi/3 etc
    
    // e^x
    input = 0;
    res = await testCalculus.testTranscendentalEvaluation(FORM.EXP, one, polarity, input, accuracy);
    expect(res).to.equal(one);

    input = one;
    let EApproximate = bn('2718281826198492860');
    res = await testCalculus.testTranscendentalEvaluation(FORM.EXP, one, polarity, input, accuracy);
    expect(res).to.equal(EApproximate);
    
  });
});
