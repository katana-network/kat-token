// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../src/MerkleMinter.sol";
import "../src/KatToken.sol";
import "../script/Deploy.s.sol";
import "./FFIHelper.sol";

contract ClaimTestSimple is Test, DeployScript {
    MerkleMinter merkleMinter;
    KatToken katToken;

    FFIHelper ffiHelper;

    // Uses the testTree.json in test/utils
    bytes32 root = 0x32523fb0ed77b9c1d8cb15a59c21fcbad1e49068a2cad9f63a017590ccd00be6;

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
        merkleMinter.unlockAndRenounceUnlocker();
        bytes32[] memory proof = ffiHelper.getProof(index);
        (uint256 leafIndex, address addr, uint256 val) = ffiHelper.getLeaf(index);
        assertEq(katToken.balanceOf(addr), 0);
        merkleMinter.claimKatToken(proof, leafIndex, val, addr);
        assertEq(katToken.balanceOf(addr), val);
    }

    function test_SimpleClaim_time_unlock_Fuzz(uint16 index) public {
        vm.assume(index < 2000);
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, address(katToken));
        vm.warp(365 * 4 days + 1 days);
        bytes32[] memory proof = ffiHelper.getProof(index);
        (uint256 leafIndex, address addr, uint256 val) = ffiHelper.getLeaf(index);
        assertEq(katToken.balanceOf(addr), 0);
        merkleMinter.claimKatToken(proof, leafIndex, val, addr);
        assertEq(katToken.balanceOf(addr), val);
    }
}

contract ClaimTestMulti is Test, DeployScript {
    MerkleMinter merkleMinter;
    KatToken katToken;

    FFIHelper ffiHelper;

    address alice = makeAddr("alice");
    uint256 totalReceived;

    // Uses the testTree.json in test/utils
    bytes32 root = 0x32523fb0ed77b9c1d8cb15a59c21fcbad1e49068a2cad9f63a017590ccd00be6;

    function setUp() public {
        ffiHelper = new FFIHelper();
        (katToken, merkleMinter) =
            deploy(dummyInflationAdmin, dummyInflationBen, dummyUnlocker, dummyRootSetter, dummyUnlockTime);

        vm.prank(dummyRootSetter);
        merkleMinter.init(root, address(katToken));
        vm.prank(dummyUnlocker);
        merkleMinter.unlockAndRenounceUnlocker();
    }

    /// forge-config: default.fuzz.runs = 10
    function test_MultiClaim_Fuzz(uint16[10] memory indexes) public {
        for (uint256 i = 0; i < indexes.length; i++) {
            uint16 index = indexes[i];
            vm.assume(index < 2000);

            bytes32[] memory proof = ffiHelper.getProof(index);
            (uint256 leafIndex, address addr, uint256 val) = ffiHelper.getLeaf(index);

            if (merkleMinter.indexIsClaimed(leafIndex)) {
                vm.expectRevert("Already claimed.");
                merkleMinter.claimKatToken(proof, leafIndex, val, addr);
            } else {
                assertEq(katToken.balanceOf(addr), 0);
                merkleMinter.claimKatToken(proof, leafIndex, val, addr);
                assertEq(katToken.balanceOf(addr), val);
                totalReceived += val;
                vm.prank(addr);
                katToken.transfer(alice, val);
                console.log(totalReceived);
                assertEq(totalReceived, katToken.balanceOf(alice));
            }
        }
    }
}
