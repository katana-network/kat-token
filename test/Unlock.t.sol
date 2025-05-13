// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../script/Deploy.s.sol";
import "../src/KatToken.sol";

contract UnlockTest is Test, DeployScript {
    KatToken token;
    address alice = makeAddr("alice");
    address beatrice = makeAddr("beatrice");
    bytes32 UNLOCKER;
    bytes32 LOCK_EXEMPTION_ADMIN;

    function setUp() public {
        token = deployDummyToken();

        UNLOCKER = token.UNLOCKER();
        LOCK_EXEMPTION_ADMIN = token.LOCK_EXEMPTION_ADMIN();
    }

    function test_locked() public {
        vm.prank(dummyDistributor);
        token.mint(alice, 10);

        vm.prank(alice);
        vm.expectRevert("Token locked.");
        token.transfer(beatrice, 10);
    }

    function test_unlock_early_no() public {
        vm.expectRevert("Not role holder.");
        token.unlockAndRenounceUnlocker();
    }

    function test_unlock_early() public {
        vm.prank(dummyDistributor);
        token.mint(alice, 100);

        vm.prank(alice);
        vm.expectRevert("Token locked.");
        token.transfer(beatrice, 10);

        assertEq(token.isUnlocked(), false);
        vm.prank(dummyUnlocker);
        token.unlockAndRenounceUnlocker();
        assertEq(token.isUnlocked(), true);
        assertEq(token.roleHolder(UNLOCKER), address(0));

        vm.prank(alice);
        token.transfer(beatrice, 10);
    }

    function test_unlock_time_based() public {
        vm.prank(dummyDistributor);
        token.mint(alice, 100);

        vm.prank(alice);
        vm.expectRevert("Token locked.");
        token.transfer(beatrice, 10);

        assertEq(token.isUnlocked(), false);
        vm.warp(dummyUnlockTime);
        assertEq(token.isUnlocked(), false);

        vm.warp(dummyUnlockTime + 1);
        assertEq(token.isUnlocked(), true);
        assertEq(token.roleHolder(UNLOCKER), dummyUnlocker);

        vm.prank(alice);
        token.transfer(beatrice, 10);

        vm.prank(dummyUnlocker);
        token.unlockAndRenounceUnlocker();
        assertEq(token.roleHolder(UNLOCKER), address(0));
    }

    function test_locked_transfer_bypass() public {
        vm.prank(dummyDistributor);
        token.mint(dummyDistributor, 10);

        vm.prank(dummyDistributor);
        token.transfer(beatrice, 10);
    }

    function test_locked_transferFrom() public {
        vm.prank(dummyDistributor);
        token.mint(dummyDistributor, 10);

        vm.prank(dummyDistributor);
        token.approve(alice, 10);

        vm.prank(alice);
        vm.expectRevert("Token locked.");
        token.transferFrom(dummyDistributor, alice, 1);

        vm.prank(dummyLockExemptionAdmin);
        token.setLockExemption(alice, true);

        vm.prank(alice);
        vm.expectRevert("Token locked.");
        token.transferFrom(dummyDistributor, alice, 1);
    }

    function test_locked_transfer_bypass_admin() public {
        vm.prank(dummyDistributor);
        token.mint(alice, 100);

        vm.prank(alice);
        vm.expectRevert("Token locked.");
        token.transfer(beatrice, 10);

        vm.prank(dummyLockExemptionAdmin);
        token.setLockExemption(alice, true);

        vm.prank(alice);
        token.transfer(beatrice, 10);

        vm.prank(beatrice);
        vm.expectRevert("Token locked.");
        token.transfer(alice, 10);
    }

    function test_locked_transfer_bypass_admin_unset() public {
        vm.prank(dummyDistributor);
        token.mint(alice, 100);

        vm.prank(alice);
        vm.expectRevert("Token locked.");
        token.transfer(beatrice, 10);

        vm.prank(dummyLockExemptionAdmin);
        token.setLockExemption(alice, true);

        vm.prank(alice);
        token.transfer(beatrice, 10);

        vm.prank(dummyLockExemptionAdmin);
        token.setLockExemption(alice, false);

        vm.prank(alice);
        vm.expectRevert("Token locked.");
        token.transfer(beatrice, 10);
    }
}
