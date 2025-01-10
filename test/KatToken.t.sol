// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../src/KatToken.sol";
import "../script/Deploy.s.sol";

contract KatTokenTest is Test, DeployScript {
    KatToken token;
    address alice = makeAddr("alice");

    function setUp() public {
        token = deployDummyToken();
    }

    function test_change_inflation_admin() public {
        vm.prank(dummyInflationAdmin);
        token.changeInflationAdmin(alice);
        assertEq(token.inflationAdmin(), alice);
    }

    function test_change_inflation_admin_permission() public {
        vm.prank(alice);
        vm.expectRevert("Not role owner.");
        token.changeInflationAdmin(alice);
    }

    function test_change_inflation_admin_no_address() public {
        vm.prank(alice);
        vm.expectRevert("Missing new owner.");
        token.changeInflationBeneficiary(address(0));
    }

    function test_change_inflation_beneficiary() public {
        vm.prank(dummyInflationBen);
        token.changeInflationBeneficiary(alice);
        assertEq(token.inflationBeneficiary(), alice);
    }

    function test_change_inflation_beneficiary_no_permission() public {
        vm.prank(alice);
        vm.expectRevert("Not role owner.");
        token.changeInflationBeneficiary(alice);
    }

    function test_change_inflation_beneficiary_no_address() public {
        vm.prank(alice);
        vm.expectRevert("Missing new owner.");
        token.changeInflationBeneficiary(address(0));
    }
}
