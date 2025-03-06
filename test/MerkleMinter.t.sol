// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../src/MerkleMinter.sol";
import "../script/Deploy.s.sol";

contract MerkleMinterTest is Test, DeployScript {
    MerkleMinter merkleMinter;
    address alice = makeAddr("alice");
    address dummyToken = makeAddr("dummyToken");

    bytes32[] proof1 = [bytes32(0x191d0f7d65eab0fa6c201d27df14a838bda49373c2ccb0fa0263334fcebd4d0e)];
    uint256 amount1 = 5000000000000000000;
    uint256 index1 = 0;
    address claimer1 = 0x1111111111111111111111111111111111111111;
    bytes32[] proof2 = [bytes32(0x006339a0971f8d293763c27967110607da32bf3548b17cce12da9fee72331612)];
    uint256 amount2 = 2500000000000000000;
    uint256 index2 = 1;
    address claimer2 = 0x2222222222222222222222222222222222222222;
    bytes32 root = 0xd16896c5291f22b49599c38d37d92f80f4819709ebdd22205a937f9c9ac5d13a;

    function setUp() public {
        merkleMinter = deployDummyMerkleMinter();
    }

    function test_locked() public {
        vm.expectRevert("Minter locked.");
        merkleMinter.claimKatToken(new bytes32[](0), 0, 0, alice);
    }

    function test_unlock_early_no() public {
        vm.expectRevert("Not unlocker.");
        merkleMinter.unlockAndRenounceUnlocker();
    }

    function test_root_setter_no() public {
        vm.expectRevert("Not rootSetter.");
        merkleMinter.init(root, dummyToken);
    }

    function test_root_setter() public {
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, dummyToken);
        assertEq(merkleMinter.root(), root);
        assertEq(address(merkleMinter.katToken()), dummyToken);
        vm.prank(dummyRootSetter);
        merkleMinter.renounceRootSetter();
        assertEq(merkleMinter.rootSetter(), address(0));
    }

    function test_root_setter_twice() public {
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, dummyToken);
        vm.expectRevert("Not rootSetter.");
        merkleMinter.init(root, dummyToken);
    }

    function test_unlock_early_claim() public {
        vm.prank(dummyUnlocker);
        merkleMinter.unlockAndRenounceUnlocker();
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, makeAddr("dummyToken"));
        vm.expectCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer1, amount1)));
        vm.mockCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer1, amount1)), "");
        merkleMinter.claimKatToken(proof1, index1, amount1, claimer1);
    }

    function test_unlock_time_claim() public {
        vm.warp(dummyUnlockTime + 1);
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, dummyToken);
        vm.expectCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer2, amount2)));
        vm.mockCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer2, amount2)), "");
        merkleMinter.claimKatToken(proof2, index2, amount2, claimer2);
    }

    function test_claim_bad_proof() public {
        vm.warp(dummyUnlockTime + 1);
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, dummyToken);
        vm.expectRevert("Proof failed");
        merkleMinter.claimKatToken(proof1, index2, amount2, claimer2);
    }

    function test_claim_twice() public {
        vm.warp(dummyUnlockTime + 1);
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, dummyToken);
        vm.expectCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer2, amount2)));
        vm.mockCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer2, amount2)), "");
        merkleMinter.claimKatToken(proof2, index2, amount2, claimer2);
        vm.expectRevert("Already claimed.");
        merkleMinter.claimKatToken(proof2, index2, amount2, claimer2);
    }
}
