// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../src/MerkleMinter.sol";
import "../src/KatToken.sol";
import "../script/Deploy.s.sol";
import "./FFIHelper.sol";

contract ClaimTest is Test, DeployScript {
    MerkleMinter merkleMinter;
    KatToken katToken;

    FFIHelper ffiHelper;

    // Uses the testTree.json in test/utils
    bytes32 root = 0x853ba80cd07a4468b83328d1742dcc7732b3df989c78221dbfaa3c01656bdeca;

    function setUp() public {
        ffiHelper = new FFIHelper();
        (katToken, merkleMinter) =
            deploy(dummyInflationAdmin, dummyInflationBen, dummyUnlocker, dummyRootSetter, dummyUnlockTime);
    }

    function test_SimpleClaim_early_unlock_Fuzz(uint16 index) public {
        vm.assume(index < 2000);
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, address(katToken));
        vm.prank(dummyUnlocker);
        merkleMinter.unlock();
        bytes32[] memory proof = ffiHelper.getProof(index);
        (address addr, uint256 val) = ffiHelper.getLeaf(index);
        assertEq(katToken.balanceOf(addr), 0);
        merkleMinter.claimKatToken(proof, val, addr);
        assertEq(katToken.balanceOf(addr), val);
    }

    function test_SimpleClaim_time_unlock_Fuzz(uint16 index) public {
        vm.assume(index < 2000);
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, address(katToken));
        vm.warp(365 * 4 days + 1 days);
        bytes32[] memory proof = ffiHelper.getProof(index);
        (address addr, uint256 val) = ffiHelper.getLeaf(index);
        assertEq(katToken.balanceOf(addr), 0);
        merkleMinter.claimKatToken(proof, val, addr);
        assertEq(katToken.balanceOf(addr), val);
    }
}
