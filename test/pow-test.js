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
    let expected = [bn(1), bn(1), bn(2), bn(6), bn(24), bn(120), bn(720)];
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

    // now check for representation of one>1
    one = 1000;

    base = 2*one;
    power = 3;
    factorialLookupBound = 4;

    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(8*one));
    base = -2*one;
    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(-8*one));
    base = 4*one;

    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(64*one));

    base = -4*one;
    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(-64*one));
    base = -7*one;
    power = 7;
    factorialLookupBound = 7;
    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(-823543).mul(bn(one)));

    // now check for rational numbers

    base = 2500; // 2.5
    power = 3;
    expect(await testPow.testPowInteger(base, power, one, factorialLookupBound)).to.equal(bn(15.625*one));

    //base = -9185915713;
    power = 5;
    one = bn(10).pow(4);//10000;
    base = bn(918591).mul(one);
    let decimals = bn(5713);
    base = base.add(decimals);
    base = base.mul(bn(-1))

    // note: this demonstrates that Pow is indeed an approximation, since otherwise this would equal bn(base).mul(one).pow(5); Pow is an approximation since full accuracy 1) is not necessarily needed, and would be expensive as far as gas goes.
    //expect((await testPow.testPowInteger(base, power, one, factorialLookupBound)).toString()).to.equal("-6540479364123122858837639765909738");
    res = await testPow.testPowIntegerGas(base, power, one, factorialLookupBound);
    res = await res.wait();
    // 62474
    // 63300 gas ??
  
    // base = -7123456789123456789 // overflows so construct using bn
    // one = 1000000000000000000
    one = bn(10).pow(18);
    base = bn(78123).mul(bn(one)); 
    decimals = bn(123456789);
    base = base.add(decimals);
    decimals = decimals.mul(bn(10).pow(9))
    base = base.add(decimals);
    base = bn(-1).mul(base);
    power = 9;
    factorialLookupBound = 9;
    expect((await testPow.testPowInteger(base, power, one, factorialLookupBound)).toString()).to.equal("-108393698117910208120989803949047816850835654671182042910689614");
    
    
  });
});
