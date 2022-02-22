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
    let expected = [1, bn(1), bn(1), bn(20), bn(3), bn(40), one];
    expect(res.form).to.equal(expected[0]);
    expect(res.scalar).to.equal(expected[1]);
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
    expect(await testCalculus.testPolynomialEvaluation(coefficients, input, one)).to.equal(bn(7575925516)); // "close" according to wolfram alpha 757.593
    //
    let FORM = {BINARYOP:0, POLYNOMIAL:1, SIN:2, COS:3, EXP:4} // etc
    
    // check differentiation
    expected = [FORM.POLYNOMIAL, bn(1), bn(20), bn(6), bn(120), one];
    for (let i=2; i<expected.length-1; i++) {
      expected[i] = expected[i].mul(one);
    }

    res = await testCalculus.testPolynomialDifferentiation(coefficients, one);
    expect(res.form).to.equal(expected[0]);
    expect(res.scalar).to.equal(expected[1]);
    for (let i=0; i<res.coefficients.length-1; i++) {
      expect(res.coefficients[i]).to.equal(expected[i+2]);
    }
    expect(res.one).to.equal(expected[expected.length-1]);
    
    // transcendentals

    let scalar = 1;
    let differentiate = false;

    res = await testCalculus.testTrigDifferentiation(FORM.SIN, one, scalar, differentiate);
    expect(res.form).to.equal(FORM.SIN);
    expect(res.scalar).to.equal(scalar);
    expect(res.one).to.equal(one);

    // differentiation ensuring sin -> cos -> -sin -> -cos ~ Z_4
    differentiate = true;
    res = await testCalculus.testTrigDifferentiation(FORM.SIN, one, scalar, differentiate);
    expect(res.form).to.equal(FORM.COS);
    expect(res.scalar).to.equal(scalar);
    expect(res.one).to.equal(one);

    res = await testCalculus.testTrigDifferentiation(FORM.COS, one, scalar, differentiate);
    expect(res.form).to.equal(FORM.SIN);
    expect(res.scalar).to.equal(-scalar);
    expect(res.one).to.equal(one);

    res = await testCalculus.testTrigDifferentiation(FORM.SIN, one, -scalar, differentiate);
    expect(res.form).to.equal(FORM.COS);
    expect(res.scalar).to.equal(-scalar);
    expect(res.one).to.equal(one);

    res = await testCalculus.testTrigDifferentiation(FORM.COS, one, -scalar, differentiate);
    expect(res.form).to.equal(FORM.SIN);
    expect(res.scalar).to.equal(scalar);
    expect(res.one).to.equal(one);

    one = bn(10).pow(18)
    // evaluate some values
    let piString = '3141592653589793238462643383279502884';
    let pi = bn(piString).mul(one).div(bn(10).pow(36));
    input = 0;
    let accuracy = 12; 
    res = await testCalculus.testTranscendentalEvaluation(FORM.SIN, one, scalar, input, accuracy);
    expect(res).to.equal(0); // sanity
    input = pi;
    res = await testCalculus.testTranscendentalEvaluation(FORM.SIN, one, scalar, input, accuracy);
    expect(res).to.equal(-32594033); // sanity ("close" to zero ) // -0.000000000032594033    
    input = 0;
    res = await testCalculus.testTranscendentalEvaluation(FORM.COS, one, scalar, input, accuracy);
    expect(res).to.equal(one); // sanity
    input = pi;
    res = await testCalculus.testTranscendentalEvaluation(FORM.COS, one, scalar, input, accuracy);
    expect(res).to.equal(bn("-1000000003423230545")); // sanity ("close" to -1)
    let piHalves = bn(piString).div(2).mul(one).div(bn(10).pow(36));
    let threePiHalves = bn(piString).mul(3).div(2).mul(one).div(bn(10).pow(36));
    input = piHalves;
    res = await testCalculus.testTranscendentalEvaluation(FORM.SIN, one, scalar, input, accuracy);
    expect(res).to.equal(bn("1000000000000000166")); // sanity ("close" to one)
    input = threePiHalves; 

    res = await testCalculus.testTranscendentalEvaluation(FORM.SIN, one, scalar, input, accuracy);
    expect(res).to.equal("-1000001333538651277"); // sanity ("close" to -1)
    //                     -682941969615792847 513603717600817265

    input = piHalves;
    res = await testCalculus.testTranscendentalEvaluation(FORM.COS, one, scalar, input, accuracy);
    expect(res).to.equal(-3598); // sanity ("close" to zero)
    
    input = threePiHalves; 
    res = await testCalculus.testTranscendentalEvaluation(FORM.COS, one, scalar, input, accuracy);
    expect(res).to.equal("-11224909331762"); // sanity ("close" to 0) //  -0.000011224909331762
    
    // TODO find methods to get better accuracy

    // TODO evaluate more values pi/2 pi/3 etc
    
    // e^x
    input = 0;
    res = await testCalculus.testTranscendentalEvaluation(FORM.EXP, one, scalar, input, accuracy);
    expect(res).to.equal(one);

    input = one;
    let EApproximate = bn('2718281826198492860');
    res = await testCalculus.testTranscendentalEvaluation(FORM.EXP, one, scalar, input, accuracy);
    expect(res).to.equal(EApproximate);

  
    // test composition
    let ones = [bn(1000), bn(100000)];
    coefficients = [[915, -10, 777], [-5401, 97, 53, -5556]];
    for (let i=0; i<coefficients.length; i++) {
      let c = coefficients[i];
      for (let j=0; j<c.length; j++) {
        coefficients[i][j] = bn(coefficients[i][j]).mul(ones[i]);
      }
    }
    let scalars = [7, -2]; // for now
    input = bn(10).mul(ones[1]); // in terms of g.one
    // composition of polynomial with polynomial
    res = await testCalculus.testComposition(ones, coefficients, scalars, input, accuracy);
    expect(res).to.equal(bn("671378855395602781000"));
    // using Geogebra for validation
    // https://www.geogebra.org/calculator
    //
    // let forms = [FORM.POLYNOMIAL, FORM.POLYNOMIAL];

    // found bug
    // // FIXME when f is of degree > 1, this is far off!!
    coefficients = [[915, -10, -44], [-5401, 97, 20]];
    for (let i=0; i<coefficients.length; i++) {
      let c = coefficients[i];
      for (let j=0; j<c.length; j++) {
        coefficients[i][j] = bn(coefficients[i][j]).mul(ones[i]);
      }
    }
    res = await testCalculus.testDifferentiateComposition(ones, coefficients, scalars, input, accuracy);
    console.log(res);
    // want 2977091628*ones[0]
  });
});
