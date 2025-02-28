//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {PowUtil} from "../../src/Powutil.sol";

contract PowUtilHarness {
    function exp2(uint256 x) public pure returns (uint256 result) {
        return PowUtil.exp2(x);
    }
}