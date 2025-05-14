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
    bytes32 LOCK_EXEMPTION_ADMIN;
    bytes32 UNLOCKER;

    uint256 one_inflation = 0.014355292977070041e18;
    uint256 two_inflation = 0.028569152196770894e18;
    uint256 three_inflation = 0.042644337408493685e18;

    function setUp() public {
        token = deployDummyToken();
        INFLATION_ADMIN = token.INFLATION_ADMIN();
        INFLATION_BENEFICIARY = token.INFLATION_BENEFICIARY();
        LOCK_EXEMPTION_ADMIN = token.LOCK_EXEMPTION_ADMIN();
        UNLOCKER = token.UNLOCKER();
    }

    function test_renounce_lock_exemption_admin() public {
        vm.prank(alice);
        vm.expectRevert("Not role holder.");
        token.renounceLockExemptionAdmin();

        vm.prank(dummyLockExemptionAdmin);
        token.renounceLockExemptionAdmin();
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

    function test_renounce_inflation_interplay_0_inflation() public {
        vm.prank(dummyInflationBen);
        vm.expectRevert("Inflation admin not 0.");
        token.renounceInflationBeneficiary();

        vm.prank(dummyInflationAdmin);
        token.renounceInflationAdmin();

        vm.prank(dummyInflationBen);
        token.renounceInflationBeneficiary();
    }

    function test_renounce_inflation_interplay_active_inflation() public {
        vm.prank(dummyInflationAdmin);
        token.changeInflation(1);
        vm.prank(dummyInflationBen);
        vm.expectRevert("Inflation not zero.");
        token.renounceInflationBeneficiary();

        vm.prank(dummyInflationAdmin);
        token.renounceInflationAdmin();
        assertEq(token.roleHolder(INFLATION_ADMIN), address(0));
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
        token.renounceInflationAdmin();

        vm.prank(dummyInflationBen);
        token.changeRoleHolder(alice, INFLATION_BENEFICIARY);
        vm.expectRevert("Role transfer in progress.");
        vm.prank(dummyInflationBen);
        token.renounceInflationBeneficiary();

        vm.prank(dummyInflationBen);
        token.changeRoleHolder(address(0), INFLATION_BENEFICIARY);

        vm.prank(dummyInflationBen);
        token.renounceInflationBeneficiary();
        assertEq(token.roleHolder(INFLATION_BENEFICIARY), address(0));
    }

    function test_full_scenario() public {
        address receiver1 = makeAddr("receiver1");
        address receiver2 = makeAddr("receiver2");
        address receiver3 = makeAddr("receiver3");
        address receiver4 = makeAddr("receiver4");
        address receiver5 = makeAddr("receiver5");

        uint256 unlockTime = vm.getBlockTimestamp() + 9 * 30 days;
        vm.setEnv("INFLATION_ADMIN", vm.toString(dummyInflationAdmin));
        vm.setEnv("INFLATION_BENEFICIARY", vm.toString(dummyInflationBen));
        vm.setEnv("UNLOCKER", vm.toString(dummyUnlocker));
        vm.setEnv("UNLOCKTIME", vm.toString(unlockTime));
        vm.setEnv("LOCK_EXEMPTION_ADMIN", vm.toString(dummyLockExemptionAdmin));
        vm.setEnv("DISTRIBUTOR", vm.toString(dummyDistributor));

        // deploy
        run();
        KatToken katToken = scriptDeployedToken;

        uint256 digits = 10 ** katToken.decimals();

        // Lock state
        vm.expectRevert("Not enough mint capacity.");
        katToken.mint(alice, 1);

        // Mint token
        vm.startPrank(dummyDistributor);
        katToken.mint(dummyDistributor, 5_000_000_000 * digits);
        katToken.mint(receiver1, 1_000_000_000 * digits);
        katToken.mint(receiver2, 2_000_000_000 * digits);
        katToken.distributeMintCapacity(receiver3, 2_000_000_000 * digits);
        vm.stopPrank();

        // test given mint rights
        vm.prank(receiver3);
        katToken.mint(receiver3, 500_000_000 * digits);

        vm.prank(receiver3);
        katToken.distributeMintCapacity(receiver4, 500_000_000 * digits);

        vm.prank(receiver3);
        vm.expectRevert("Token locked.");
        katToken.transfer(receiver4, 500_000_000 * digits);

        vm.prank(dummyLockExemptionAdmin);
        katToken.setLockExemption(receiver3);
        vm.prank(receiver3);
        katToken.transfer(receiver4, 500_000_000 * digits);

        // Overmint
        vm.prank(dummyDistributor);
        vm.expectRevert("Not enough mint capacity.");
        katToken.mint(dummyDistributor, 1);

        // Transfer
        vm.prank(dummyDistributor);
        katToken.transfer(alice, 1_000_000_000 * digits);

        // Transfer lock
        vm.prank(alice);
        vm.expectRevert("Token locked.");
        katToken.transfer(beatrice, 1);

        // Transfer lock to exempt
        vm.prank(alice);
        vm.expectRevert("Token locked.");
        katToken.transfer(dummyDistributor, 1);

        // Transfer lock exemption
        vm.prank(receiver1);
        vm.expectRevert("Token locked.");
        katToken.transfer(alice, 1);

        vm.prank(dummyLockExemptionAdmin);
        katToken.setLockExemption(receiver1);

        vm.prank(receiver1);
        katToken.transfer(alice, 1);

        vm.prank(dummyLockExemptionAdmin);
        katToken.setLockExemption(receiver1);

        vm.prank(receiver1);
        vm.expectRevert("Token locked.");
        katToken.transfer(alice, 1);

        // wait for unlock
        vm.warp(unlockTime);
        vm.prank(receiver1);
        vm.expectRevert("Token locked.");
        katToken.transfer(alice, 1);

        // actual unlock
        vm.warp(unlockTime + 1);

        vm.prank(alice);
        katToken.transfer(beatrice, 1);

        vm.prank(dummyDistributor);
        katToken.transfer(receiver1, 1);

        // enable inflation
        assertEq(katToken.mintCapacity(dummyInflationBen), 0);
        vm.prank(dummyInflationAdmin);
        katToken.changeInflation(one_inflation);

        // wait one year
        vm.warp(vm.getBlockTimestamp() + 365 days);
        katToken.distributeInflation();
        assertApproxEqAbsDecimal(katToken.cap(), 10_100_000_000 * digits, 10 * digits, 0);
        uint256 currentMintCap = katToken.mintCapacity(dummyInflationBen);
        assertApproxEqAbsDecimal(currentMintCap, 100_000_000 * digits, 10 * digits, 0);
        vm.prank(dummyInflationBen);
        katToken.mint(dummyInflationBen, currentMintCap);

        // increase inflation
        vm.prank(dummyInflationAdmin);
        katToken.changeInflation(two_inflation);

        // wait one more year
        vm.warp(vm.getBlockTimestamp() + 365 days);
        address dummyInflationBen2 = makeAddr("dummyInflationBen2");

        // switch inflation ben
        vm.prank(dummyInflationBen);
        katToken.changeRoleHolder(dummyInflationBen2, INFLATION_BENEFICIARY);
        vm.prank(dummyInflationBen2);
        katToken.acceptRole(INFLATION_BENEFICIARY);

        katToken.distributeInflation();
        currentMintCap = katToken.mintCapacity(dummyInflationBen2);
        assertApproxEqAbsDecimal(katToken.cap(), 10_302_000_000 * digits, 10 * digits, 0);
        assertApproxEqAbsDecimal(currentMintCap, 202_000_000 * digits, 10 * digits, 0);

        // mint and distribute
        vm.prank(dummyInflationBen2);
        katToken.distributeMintCapacity(receiver5, 100_000_000 * digits);
        vm.prank(receiver5);
        katToken.mint(receiver5, 100_000_000 * digits);
        vm.prank(dummyInflationBen2);
        katToken.mint(dummyInflationBen2, currentMintCap - 100_000_000 * digits);
    }
}
