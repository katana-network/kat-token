// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../src/KatToken.sol";
import "../script/Deploy.s.sol";

contract KatTokenTest is Test, DeployScript {
    KatToken token;
    address alice = makeAddr("alice");
    address beatrice = makeAddr("beatrice");

    function setUp() public {
        token = deployDummyToken();
    }

    function test_change_role() public {
        bytes32 role = token.INFLATION_ADMIN();
        vm.prank(dummyInflationAdmin);
        token.changeRole(alice, role);
        assertEq(token.roles(role), alice);
    }

    function test_change_role_no_permission() public {
        bytes32 role = token.INFLATION_ADMIN();
        vm.prank(alice);
        vm.expectRevert("Not role owner.");
        token.changeRole(alice, role);
    }

    function test_change_role_no_address() public {
        bytes32 role = token.INFLATION_ADMIN();
        vm.prank(alice);
        vm.expectRevert("Missing new owner.");
        token.changeRole(address(0), role);
    }

    function test_change_role_no_role() public {
        bytes32 role = keccak256("empty_role");
        vm.prank(alice);
        vm.expectRevert("Not role owner.");
        token.changeRole(alice, role);

        vm.prank(dummyInflationAdmin);
        vm.expectRevert("Not role owner.");
        token.changeRole(alice, role);
    }
}
