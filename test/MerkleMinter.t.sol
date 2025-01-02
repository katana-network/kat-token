// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../src/MerkleMinter.sol";
import "../script/Deploy.s.sol";

contract MerkleMinterTest is Test, DeployScript {
    MerkleMinter merkleMinter;
    address alice = makeAddr("alice");
    address beatrice = makeAddr("beatrice");
    address dummyToken = makeAddr("dummyToken");

    bytes32[] proof1 = [bytes32(0xb92c48e9d7abe27fd8dfd6b5dfdbfb1c9a463f80c712b66f3a5180a090cccafc)];
    uint256 amount1 = 5000000000000000000;
    address claimer1 = 0x1111111111111111111111111111111111111111;
    bytes32[] proof2 = [bytes32(0xeb02c421cfa48976e66dfb29120745909ea3a0f843456c263cf8f1253483e283)];
    uint256 amount2 = 2500000000000000000;
    address claimer2 = 0x2222222222222222222222222222222222222222;
    bytes32 root = 0xd4dee0beab2d53f2cc83e567171bd2820e49898130a22622b10ead383e90bd77;

    function setUp() public {
        merkleMinter = deployDummyMerkleMinter();
    }

    function test_locked() public {
        vm.expectRevert("Minter locked.");
        merkleMinter.claimKatToken(new bytes32[](0), 0, alice);
    }

    function test_unlock_early_no() public {
        vm.expectRevert("Not unlocker.");
        merkleMinter.unlock();
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
    }

    function test_root_setter_twice() public {
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, dummyToken);
        vm.expectRevert("Not rootSetter.");
        merkleMinter.init(root, dummyToken);
    }

    function test_unlock_early_claim() public {
        vm.prank(dummyUnlocker);
        merkleMinter.unlock();
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, makeAddr("dummyToken"));
        vm.expectCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer1, amount1)));
        vm.mockCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer1, amount1)), "");
        merkleMinter.claimKatToken(proof1, amount1, claimer1);
    }

    function test_unlock_time_claim() public {
        vm.warp(dummyUnlockTime + 1);
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, dummyToken);
        vm.expectCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer2, amount2)));
        vm.mockCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer2, amount2)), "");
        merkleMinter.claimKatToken(proof2, amount2, claimer2);
    }

    function test_claim_bad_proof() public {
        vm.warp(dummyUnlockTime + 1);
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, dummyToken);
        vm.expectRevert("Proof failed");
        merkleMinter.claimKatToken(proof1, amount2, claimer2);
    }

    function test_claim_twice() public {
        vm.warp(dummyUnlockTime + 1);
        vm.prank(dummyRootSetter);
        merkleMinter.init(root, dummyToken);
        vm.expectCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer2, amount2)));
        vm.mockCall(dummyToken, abi.encodeCall(KatToken.mintTo, (claimer2, amount2)), "");
        merkleMinter.claimKatToken(proof2, amount2, claimer2);
        vm.expectRevert("Already claimed.");
        merkleMinter.claimKatToken(proof2, amount2, claimer2);
    }

    function test_mint_inflation() public {
        // do some inflation
        // delegate the inflation to soemone
        // have them mint the inflation
    }
}
