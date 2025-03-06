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

    function test_change_inflation_admin() public {
        vm.prank(dummyInflationAdmin);
        vm.expectEmit(true, true, true, true);
        emit KatToken.InflationAdminChanged(alice, true);
        token.changeInflationAdmin(alice);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit KatToken.InflationAdminChanged(alice, false);
        token.acceptInflationAdmin();
        assertEq(token.inflationAdmin(), alice);
    }

    function test_change_inflation_admin_permission() public {
        vm.prank(alice);
        vm.expectRevert("Not role owner.");
        token.changeInflationAdmin(alice);
    }

    function test_accept_inflation_admin_empty() public {
        vm.prank(alice);
        vm.expectRevert("Not new role owner.");
        token.acceptInflationAdmin();
    }

    function test_accept_inflation_admin_wrong() public {
        vm.prank(dummyInflationAdmin);
        vm.expectEmit(true, true, true, true);
        emit KatToken.InflationAdminChanged(alice, true);
        token.changeInflationAdmin(alice);
        vm.prank(beatrice);
        vm.expectRevert("Not new role owner.");
        token.acceptInflationAdmin();
    }

    function test_change_inflation_beneficiary() public {
        vm.prank(dummyInflationBen);
        vm.expectEmit(true, true, true, true);
        emit KatToken.InflationBeneficiaryChanged(alice, true);
        token.changeInflationBeneficiary(alice);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit KatToken.InflationBeneficiaryChanged(alice, false);
        token.acceptInflationBeneficiary();
        assertEq(token.inflationBeneficiary(), alice);
    }

    function test_change_inflation_beneficiary_no_permission() public {
        vm.prank(alice);
        vm.expectRevert("Not role owner.");
        token.changeInflationBeneficiary(alice);
    }

    function test_accept_inflation_beneficiary_empty() public {
        vm.prank(alice);
        vm.expectRevert("Not new role owner.");
        token.acceptInflationBeneficiary();
    }

    function test_accept_inflation_beneficiary_wrong() public {
        vm.prank(dummyInflationBen);
        vm.expectEmit(true, true, true, true);
        emit KatToken.InflationBeneficiaryChanged(alice, true);
        token.changeInflationBeneficiary(alice);
        vm.prank(beatrice);
        vm.expectRevert("Not new role owner.");
        token.acceptInflationBeneficiary();
    }
}
