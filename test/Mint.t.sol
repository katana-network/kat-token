// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../src/KatToken.sol";
import "../script/Deploy.s.sol";

contract MintTest is Test, DeployScript {
    KatToken token;
    address alice = makeAddr("alice");
    address beatrice = makeAddr("beatrice");

    function setUp() public {
        token = deployDummyToken();
    }

    function test_mint_distribution() public {
        warpYears(5);
        token.distributeInflation();
        uint256 originalCapacity = token.mintCapacity(dummyInflationBen);
        vm.prank(dummyInflationBen);
        token.distributeMintCapacity(alice, 5000);
        assertEq(5000, token.mintCapacity(alice));
        assertEq(originalCapacity - 5000, token.mintCapacity(dummyInflationBen));
    }

    function test_mint_distribution_over() public {
        warpYears(5);
        token.distributeInflation();
        uint256 originalCapacity = token.mintCapacity(dummyInflationBen);
        vm.expectRevert("Not enough mint capacity.");
        vm.prank(dummyInflationBen);
        token.distributeMintCapacity(alice, originalCapacity + 1);
    }

    function test_no_capacity() public {
        assertEq(token.mintCapacity(alice), 0);
        vm.prank(alice);
        vm.expectRevert("Not enough mint capacity.");
        token.distributeMintCapacity(beatrice, 1);
    }

    function test_no_send_0x() public {
        warpYears(5);
        token.distributeInflation();
        uint256 originalCapacity = token.mintCapacity(dummyInflationBen);
        vm.expectRevert("Sending to 0 address");
        vm.prank(dummyInflationBen);
        token.distributeMintCapacity(address(0), originalCapacity);
    }

    function test_mintTo() public {
        uint256 allCapacity = token.mintCapacity(dummyMerkleMinter);
        vm.prank(dummyMerkleMinter);
        token.mintTo(alice, allCapacity / 2);
        assertEq(token.balanceOf(alice), allCapacity / 2);
        assertEq(token.mintCapacity(dummyMerkleMinter), allCapacity / 2);

        vm.prank(dummyMerkleMinter);
        token.mintTo(beatrice, allCapacity / 4);
        assertEq(token.balanceOf(beatrice), allCapacity * 1 / 4);
        assertEq(token.mintCapacity(dummyMerkleMinter), allCapacity * 1 / 4);
    }

    function test_mintTo_fail() public {
        vm.prank(alice);
        vm.expectRevert("Not enough mint capacity.");
        token.mintTo(beatrice, 10);
        uint256 allCapacity = token.mintCapacity(dummyMerkleMinter);
        vm.prank(dummyMerkleMinter);
        vm.expectRevert("Not enough mint capacity.");
        token.mintTo(beatrice, allCapacity + 1);
    }

    function warpYears(uint256 amount) internal {
        vm.warp(365 days * amount + (amount / 4) * 1 days);
    }
}
