// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../src/KatToken.sol";
import "../script/Deploy.s.sol";

contract InflationTest is Test, DeployScript {
    KatToken token;
    uint256 one_inflation = 0.014355292977070041e18;
    uint256 two_inflation = 0.028569152196770894e18;
    uint256 three_inflation = 0.042644337408493685e18;

    uint256 decimals;

    function setUp() public {
        token = deployDummyToken();
        decimals = 10 ** token.decimals();
    }

    function test_zero_Inflation() public {
        assertEq(token.cap(), 10_000_000_000 * decimals);
        vm.warp(1 days);
        assertEq(token.cap(), 10_000_000_000 * decimals);
        vm.warp(8 days);
        assertEq(token.cap(), 10_000_000_000 * decimals);
        warpYears(4);
        assertEq(token.cap(), 10_000_000_000 * decimals);
        warpYears(5);

        // Aim for less than 10 token error
        // One second later would be more exact, but leap seconds can't be predicted, so useless to aim for that accuracy
        assertApproxEqAbsDecimal(token.cap(), 10_000_000_000 * decimals, 10 * decimals, 0);

        warpYears(6);
        assertApproxEqAbsDecimal(token.cap(), 10_000_000_000 * decimals, 10 * decimals, 0);
    }

    function test_over_Max_Inflation() public {
        vm.startPrank(dummyInflationAdmin);
        uint256 max_inflation = token.MAX_INFLATION();
        vm.expectRevert("Inflation too large.");
        token.changeInflation(max_inflation + 1);

        vm.expectRevert("Inflation too large.");
        token.changeInflation(10000000000000000000000);
    }

    function test_Max_Inflation_expected_value() public {
        vm.startPrank(dummyInflationAdmin);
        uint256 max_inflation = token.MAX_INFLATION();
        token.changeInflation(max_inflation);

        warpYears(1);
        assertApproxEqAbsDecimal(token.cap(), 133_700_000_000 * decimals, 20000 * decimals, 0);
    }

    function test_start_Inflation() public {
        assertEq(token.cap(), 10_000_000_000 * decimals);
        vm.warp(1 days);
        assertEq(token.cap(), 10_000_000_000 * decimals);
        vm.warp(8 days);
        assertEq(token.cap(), 10_000_000_000 * decimals);
        warpYears(4);
        assertEq(token.cap(), 10_000_000_000 * decimals);

        vm.prank(dummyInflationAdmin);
        token.changeInflation(two_inflation);
        warpYears(5);
        assertApproxEqAbsDecimal(token.cap(), 10_200_000_000 * decimals, 10 * decimals, 0);
        warpYears(6);
        assertApproxEqAbsDecimal(token.cap(), 10_404_000_000 * decimals, 10 * decimals, 0);
    }

    function test_changed_Inflation2() public {
        assertEq(token.totalSupply(), 0);
        assertEq(token.cap(), 10_000_000_000 * decimals);

        vm.prank(dummyDistributor);
        token.mint(dummyDistributor, 10_000_000_000 * decimals);

        vm.prank(dummyInflationAdmin);
        token.changeInflation(three_inflation);
        assertEq(token.cap(), 10_000_000_000 * decimals);
        assertEq(token.totalSupply(), 10_000_000_000 * decimals);

        warpYears(1);
        assertApproxEqAbsDecimal(token.cap(), 10_300_000_000 * decimals, 10 * decimals, 0);
        assertEq(token.totalSupply(), 10_000_000_000 * decimals);

        warpYears(2);
        assertApproxEqAbsDecimal(token.cap(), 10_609_000_000 * decimals, 10 * decimals, 0);
        token.distributeInflation();
        uint256 toBeMinted = token.mintCapacity(dummyInflationBen);
        vm.prank(dummyInflationBen);
        token.mint(dummyInflationAdmin, toBeMinted);
        assertEq(token.totalSupply(), token.cap());

        vm.prank(dummyInflationAdmin);
        token.changeInflation(one_inflation);
        warpYears(3);
        // using 11 here should be fine as we want 10 token per year max off
        assertApproxEqAbsDecimal(token.cap(), 10_715_090_000 * decimals, 11 * decimals, 0);

        vm.prank(dummyInflationAdmin);
        token.changeInflation(0);
        warpYears(4);
        // using 11 here should be fine as we want 10 token per year max off
        assertApproxEqAbsDecimal(token.cap(), 10_715_090_000 * decimals, 11 * decimals, 0);
    }

    function test_Inflation_access() public {
        vm.expectRevert("Not role holder.");
        token.changeInflation(one_inflation);
    }

    function test_Inflation_distribution_ben() public {
        assertEq(token.mintCapacity(dummyInflationBen), 0);
        warpYears(4);
        assertEq(token.mintCapacity(dummyInflationBen), 0);
        vm.prank(dummyInflationAdmin);
        token.changeInflation(two_inflation);
        warpYears(5);
        assertEq(token.mintCapacity(dummyInflationBen), 0);
        token.distributeInflation();
        assertApproxEqAbsDecimal(token.mintCapacity(dummyInflationBen), 200_000_000 * decimals, 10 * decimals, 0);
        warpYears(6);
        assertApproxEqAbsDecimal(token.mintCapacity(dummyInflationBen), 200_000_000 * decimals, 10 * decimals, 0);
        token.distributeInflation();
        assertApproxEqAbsDecimal(token.mintCapacity(dummyInflationBen), 404_000_000 * decimals, 10 * decimals, 0);
    }

    function test_Inflation_distribution_early() public {
        token.distributeInflation();
        assertEq(token.mintCapacity(dummyInflationBen), 0);
    }

    function test_Inflation_distributor() public {
        assertEq(token.mintCapacity(dummyDistributor), 10_000_000_000 * decimals);
        warpYears(4);
        assertEq(token.mintCapacity(dummyDistributor), 10_000_000_000 * decimals);
        warpYears(6);
        assertEq(token.mintCapacity(dummyDistributor), 10_000_000_000 * decimals);
        token.distributeInflation();
        assertEq(token.mintCapacity(dummyDistributor), 10_000_000_000 * decimals);
    }

    function warpYears(uint256 amount) internal {
        vm.warp(365 days * amount + (amount / 4) * 1 days);
    }
}
