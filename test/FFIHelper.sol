// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";

contract FFIHelper is Test {
    function calcInflation(
        uint256 timeElapsedInSeconds,
        uint256 lastSupply,
        uint256 inflationRatePerYear
    ) public returns (uint256) {
        string[] memory ffiInputs = new string[](5);
        ffiInputs[0] = "node";
        ffiInputs[1] = "test/utils/calcInflation.js";
        ffiInputs[2] = vm.toString(timeElapsedInSeconds); // time since last realization in secondss
        ffiInputs[3] = vm.toString(lastSupply); // supply at the last realization
        ffiInputs[4] = string.concat("1.0", vm.toString(inflationRatePerYear)); // example: 2
        return abi.decode(vm.ffi(ffiInputs), (uint256));
    }

    function getProof(uint256 index) public returns (bytes32[] memory) {
        string[] memory ffiInputs = new string[](3);
        ffiInputs[0] = "node";
        ffiInputs[1] = "test/utils/getProof.js";
        ffiInputs[2] = vm.toString(index); // leaf index
        bytes memory res = vm.ffi(ffiInputs);
        return abi.decode(res, (bytes32[]));
    }

    function getLeaf(uint256 index) public returns (address, uint256) {
        string[] memory ffiInputs = new string[](3);
        ffiInputs[0] = "node";
        ffiInputs[1] = "test/utils/getLeaf.js";
        ffiInputs[2] = vm.toString(index); // leaf index
        return abi.decode(vm.ffi(ffiInputs), (address, uint256));
    }

    function gen() public {
        console.log("[");
        for (uint256 i = 0; i < 2000; i++) {
            //0x240A3d2eBc8AAf892347f73070F668cD556C7a8b 52064
            // ["0x1111111111111111111111111111111111111111", "5000000000000000000"],
            console.log('["');
            console.log(vm.randomAddress());
            console.log('" ,"');
            console.log(vm.randomUint(0, 100000));
            console.log('"],');
        }
        console.log("]");
    }
}
