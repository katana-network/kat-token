// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../src/KatToken.sol";
import "../script/Deploy.s.sol";

contract KatTokenTest is Test, DeployScript {
    KatToken token;
    address alice = makeAddr("alice");
    address beatrice = makeAddr("beatrice");
    bytes32 INFLATION_ADMIN;
    bytes32 INFLATION_BENEFICIARY;

    function setUp() public {
        token = deployDummyToken();
        INFLATION_ADMIN = token.INFLATION_ADMIN();
        INFLATION_BENEFICIARY = token.INFLATION_BENEFICIARY();
    }

    function test_change_inflation_admin() public {
        vm.prank(dummyInflationAdmin);
        vm.expectEmit(true, true, true, true);
        emit KatToken.RoleChangeStarted(alice, INFLATION_ADMIN);
        token.changeRoleHolder(alice, INFLATION_ADMIN);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit KatToken.RoleChangeCompleted(alice, INFLATION_ADMIN);
        token.acceptRole(INFLATION_ADMIN);
        assertEq(token.roleHolder(INFLATION_ADMIN), alice);
    }

    function test_change_inflation_admin_permission() public {
        vm.prank(alice);
        vm.expectRevert("Not role holder.");
        token.changeRoleHolder(alice, INFLATION_ADMIN);
    }

    function test_accept_inflation_admin_empty() public {
        vm.prank(alice);
        vm.expectRevert("Not new role holder.");
        token.acceptRole(INFLATION_ADMIN);
    }

    function test_accept_inflation_admin_wrong() public {
        vm.prank(dummyInflationAdmin);
        vm.expectEmit(true, true, true, true);
        emit KatToken.RoleChangeStarted(alice, INFLATION_ADMIN);
        token.changeRoleHolder(alice, INFLATION_ADMIN);
        vm.prank(beatrice);
        vm.expectRevert("Not new role holder.");
        token.acceptRole(INFLATION_ADMIN);
    }

    function test_renounce_inflation_admin() public {
        vm.prank(alice);
        vm.expectRevert("Not role holder.");
        token.renounceInflationAdmin();

        vm.prank(dummyInflationAdmin);
        token.renounceInflationAdmin();
        assertEq(token.roleHolder(INFLATION_ADMIN), address(0));
    }

    function test_renounce_inflation_admin_inprogress() public {
        vm.prank(dummyInflationAdmin);
        token.changeRoleHolder(alice, INFLATION_ADMIN);
        vm.prank(dummyInflationAdmin);
        vm.expectRevert("Role transfer in progress.");
        token.renounceInflationAdmin();

        vm.prank(dummyInflationAdmin);
        token.changeRoleHolder(address(0), INFLATION_ADMIN);
        vm.prank(dummyInflationAdmin);
        token.renounceInflationAdmin();
        assertEq(token.roleHolder(INFLATION_ADMIN), address(0));
    }

    function test_change_inflation_beneficiary() public {
        vm.prank(dummyInflationBen);
        vm.expectEmit(true, true, true, true);
        emit KatToken.RoleChangeStarted(alice, INFLATION_BENEFICIARY);
        token.changeRoleHolder(alice, INFLATION_BENEFICIARY);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit KatToken.RoleChangeCompleted(alice, INFLATION_BENEFICIARY);
        token.acceptRole(INFLATION_BENEFICIARY);
        assertEq(token.roleHolder(INFLATION_BENEFICIARY), alice);
    }

    function test_change_inflation_beneficiary_no_permission() public {
        vm.prank(alice);
        vm.expectRevert("Not role holder.");
        token.changeRoleHolder(alice, INFLATION_BENEFICIARY);
    }

    function test_accept_inflation_beneficiary_empty() public {
        vm.prank(alice);
        vm.expectRevert("Not new role holder.");
        token.acceptRole(INFLATION_BENEFICIARY);
    }

    function test_accept_inflation_beneficiary_wrong() public {
        vm.prank(dummyInflationBen);
        vm.expectEmit(true, true, true, true);
        emit KatToken.RoleChangeStarted(alice, INFLATION_BENEFICIARY);
        token.changeRoleHolder(alice, INFLATION_BENEFICIARY);
        vm.prank(beatrice);
        vm.expectRevert("Not new role holder.");
        token.acceptRole(INFLATION_BENEFICIARY);
    }

    function test_renounce_inflation_beneficiary() public {
        vm.prank(alice);
        vm.expectRevert("Not role holder.");
        token.renounceInflationBeneficiary();

        vm.prank(dummyInflationAdmin);
        token.changeInflation(2);

        vm.prank(dummyInflationBen);
        vm.expectRevert("Inflation not zero.");
        token.renounceInflationBeneficiary();

        vm.prank(dummyInflationAdmin);
        token.changeInflation(0);
        vm.prank(dummyInflationBen);
        vm.expectRevert("Inflation admin not 0.");
        token.renounceInflationBeneficiary();

        vm.prank(dummyInflationAdmin);
        token.renounceInflationAdmin();
        vm.prank(dummyInflationBen);
        token.renounceInflationBeneficiary();
        assertEq(token.roleHolder(INFLATION_BENEFICIARY), address(0));
    }

    function test_renounce_inflation_beneficiary_inprogress() public {
        vm.prank(dummyInflationAdmin);
        token.changeInflation(0);

        vm.prank(dummyInflationBen);
        token.changeRoleHolder(alice, INFLATION_BENEFICIARY);
        vm.expectRevert("Role transfer in progress.");
        vm.prank(dummyInflationBen);
        token.renounceInflationBeneficiary();

        vm.prank(dummyInflationAdmin);
        token.renounceInflationAdmin();
        vm.prank(dummyInflationBen);
        token.changeRoleHolder(address(0), INFLATION_BENEFICIARY);
        vm.prank(dummyInflationBen);
        token.renounceInflationBeneficiary();
        assertEq(token.roleHolder(INFLATION_BENEFICIARY), address(0));
    }
}
