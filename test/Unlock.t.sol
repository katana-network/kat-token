// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "dependencies/forge-std-1.9.4/src/Test.sol";
import "../script/Deploy.s.sol";
import "../src/KatToken.sol";

contract UnlockTest is Test, DeployScript {
    KatToken katToken;
    address alice = makeAddr("alice");
    address dummyToken = makeAddr("dummyToken");

    function setUp() public {
        katToken = deployDummyToken();
    }

    function test_locked() public {
        vm.expectRevert("Minter locked.");
    }

    function test_unlock_early_no() public {
        vm.expectRevert("Not unlocker.");
        katToken.unlockAndRenounceUnlocker();
    }
}
