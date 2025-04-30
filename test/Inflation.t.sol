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

    function test_Default_Inflation() public {
        assertCorrectCap([uint256(10_200_000_000 * decimals), 10_404_000_000 * decimals]);
    }

    function test_Max_Inflation() public {
        vm.prank(dummyInflationAdmin);
        token.changeInflation(three_inflation);
        assertCorrectCap([uint256(10_300_000_000 * decimals), 10_609_000_000 * decimals]);
    }

    function test_zero_Inflation() public {
        vm.prank(dummyInflationAdmin);
        token.changeInflation(0);
        assertCorrectCap([uint256(10_000_000_000 * decimals), 10_000_000_000 * decimals]);
    }

    function test_changed_Inflation() public {
        vm.startPrank(dummyInflationAdmin);
        assertEq(token.cap(), 10_000_000_000 * decimals);
        warpYears(4);
        assertEq(token.cap(), 10_000_000_000 * decimals);
        warpYears(5);
        assertApproxEqAbsDecimal(token.cap(), 10_200_000_000 * decimals, 10 * decimals, 0);
        token.changeInflation(0);
        warpYears(6);
        assertApproxEqAbsDecimal(token.cap(), 10_200_000_000 * decimals, 10 * decimals, 0);
        token.changeInflation(two_inflation);
        warpYears(7);
        assertApproxEqAbsDecimal(token.cap(), 10_404_000_000 * decimals, 10 * decimals, 0);
    }

    function test_changed_Inflation2() public {
        vm.startPrank(dummyInflationAdmin);
        token.changeInflation(0);
        assertEq(token.cap(), 10_000_000_000 * decimals);
        warpYears(4);
        assertEq(token.cap(), 10_000_000_000 * decimals);
        warpYears(5);
        assertApproxEqAbsDecimal(token.cap(), 10_000_000_000 * decimals, 10 * decimals, 0);
        token.changeInflation(one_inflation);
        warpYears(6);
        assertApproxEqAbsDecimal(token.cap(), 10_100_000_000 * decimals, 10 * decimals, 0);
        token.changeInflation(two_inflation);
        warpYears(7);
        assertApproxEqAbsDecimal(token.cap(), 10_302_000_000 * decimals, 10 * decimals, 0);
    }

    function test_Inflation_access() public {
        vm.expectRevert("Not role owner.");
        token.changeInflation(0);
    }

    function test_Inflation_distribution_ben() public {
        assertEq(token.mintCapacity(dummyInflationBen), 0);
        warpYears(4);
        assertEq(token.mintCapacity(dummyInflationBen), 0);
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

    function test_Inflation_distribution_merkle() public {
        assertEq(token.mintCapacity(dummyMerkleMinter), 10_000_000_000 * decimals);
        warpYears(4);
        assertEq(token.mintCapacity(dummyMerkleMinter), 10_000_000_000 * decimals);
        warpYears(6);
        assertEq(token.mintCapacity(dummyMerkleMinter), 10_000_000_000 * decimals);
        token.distributeInflation();
        assertEq(token.mintCapacity(dummyMerkleMinter), 10_000_000_000 * decimals);
    }

    function warpYears(uint256 amount) internal {
        vm.warp(365 days * amount + (amount / 4) * 1 days);
    }

    function assertCorrectCap(uint256[2] memory expectedCap) internal {
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
        assertApproxEqAbsDecimal(token.cap(), expectedCap[0], 10 * decimals, 0);

        warpYears(6);
        assertApproxEqAbsDecimal(token.cap(), expectedCap[1], 10 * decimals, 0);
    }
}
