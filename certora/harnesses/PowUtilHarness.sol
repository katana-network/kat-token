//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {PowUtil} from "../../src/Powutil.sol";

// Makes it easier to access `PowUtil.exp2`.
contract PowUtilHarness {
    function exp2(uint256 x) public pure returns (uint256 result) {
        return PowUtil.exp2(x);
    }
}