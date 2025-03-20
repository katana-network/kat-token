// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script, console} from "dependencies/forge-std-1.9.4/src/Script.sol";
import {KatToken} from "../src/KatToken.sol";
import {MerkleMinter} from "../src/MerkleMinter.sol";

contract DeployScript is Script {
    string constant tokenName = "KAT Token";
    string constant tokenSymbol = "KAT";

    bytes32 constant salt = "funny text";
    address dummyInflationAdmin = makeAddr("inflation_admin");
    address dummyInflationBen = makeAddr("inflation_ben");
    address dummyMerkleMinter = makeAddr("inflation_admin");
    address dummyUnlocker = makeAddr("unlocker");
    address dummyRootSetter = makeAddr("rootsetter");
    uint256 dummyUnlockTime = block.timestamp + 9 days;

    function run() public {
        (KatToken katToken, MerkleMinter merkleMinter) =
            deploy(dummyInflationAdmin, dummyInflationBen, dummyUnlocker, dummyMerkleMinter, dummyUnlockTime);
        console.log("KAT Token address: ", address(katToken));
        console.log("MerkleMinter address: ", address(merkleMinter));
    }

    function deploy(
        address _inflation_admin,
        address _inflation_ben,
        address _unlocker,
        address _rootSetter,
        uint256 _unlockDelay
    ) public returns (KatToken katToken, MerkleMinter merkleMinter) {
        // uint256 _unlockTime
        // address _unlocker
        // address _rootSetter
        merkleMinter = new MerkleMinter{salt: salt}(_unlockDelay, _unlocker, _rootSetter);

        // string memory name,
        // string memory symbol,
        // address inflation_admin,
        // address inflation_beneficiary,
        // address _merkleMinter
        katToken = new KatToken{salt: salt}("KatToken", "KAT", _inflation_admin, _inflation_ben, address(merkleMinter));
    }

    function deployDummyToken() public returns (KatToken katToken) {
        return new KatToken{salt: salt}("KatToken", "KAT", dummyInflationAdmin, dummyInflationBen, dummyMerkleMinter);
    }

    function deployDummyMerkleMinter() public returns (MerkleMinter merkleMinter) {
        return new MerkleMinter{salt: salt}(dummyUnlockTime, dummyUnlocker, dummyRootSetter);
    }
}
