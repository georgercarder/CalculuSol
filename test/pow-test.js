const { expect } = require("chai");
const { ethers } = require("hardhat");

function bn(number) {
  return new ethers.BigNumber.from(number);
}

describe("TestPow", function () {
  it("checks correctness of Pow library", async function () {
    const TestPow = await ethers.getContractFactory("TestPow");
    const testPow = await TestPow.deploy();
    await testPow.deployed();

    let res = await testPow.testFactorialLookupTable(6);
    let expected = [bn(2), bn(6), bn(24), bn(120), bn(720)];
    for (let i=0; i<res.length; i++) {
      expect(res[i]).to.equal(expected[i]);
    }

    let base = 2;
    let power = 3;
    let one = 1;
    let factorialLookupBound = 4;
    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(8));
    base = -2;
    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(-8));
    base = 4;

    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(64));

    base = -4;
    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(-64));
    base = -7;
    power = 7;
    factorialLookupBound = 7;
    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(-823543));

    //expect(await testPow.greet()).to.equal("Hello, world!");
  });
});
