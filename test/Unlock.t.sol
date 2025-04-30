// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../script/Deploy.s.sol";
import "../src/KatToken.sol";

contract UnlockTest is Test, DeployScript {
    KatToken token;
    address alice = makeAddr("alice");
    address beatrice = makeAddr("beatrice");

    address dummyToken = makeAddr("dummyToken");

    function setUp() public {
        token = deployDummyToken();
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
}
