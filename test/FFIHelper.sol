// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";

contract FFIHelper is Test {
    function getProof(uint256 index) public returns (bytes32[] memory) {
        string[] memory ffiInputs = new string[](3);
        ffiInputs[0] = "node";
        ffiInputs[1] = "test/utils/getProof.js";
        ffiInputs[2] = vm.toString(index); // leaf index
        bytes memory res = vm.ffi(ffiInputs);
        return abi.decode(res, (bytes32[]));
    }

    function getLeaf(uint256 index) public returns (uint256, address, uint256) {
        string[] memory ffiInputs = new string[](3);
        ffiInputs[0] = "node";
        ffiInputs[1] = "test/utils/getLeaf.js";
        ffiInputs[2] = vm.toString(index); // leaf index
        return abi.decode(vm.ffi(ffiInputs), (uint256, address, uint256));
    }
}
