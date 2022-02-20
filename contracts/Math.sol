// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Math {

  function abs(int x) internal pure returns(int) {
    return (x>0) ? x : -x;
  }

}
