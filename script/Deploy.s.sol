// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script, console} from "dependencies/forge-std-1.9.4/src/Script.sol";
import {KatToken} from "../src/KatToken.sol";
import {MerkleMinter} from "../src/MerkleMinter.sol";

contract DeployScript is Script {
    string constant tokenName = "KAT Token";
    string constant tokenSymbol = "KAT";

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        (KatToken katToken, MerkleMinter merkleMinter) = deploy(
            makeAddr("admin"),
            makeAddr("inflation_ben"),
            makeAddr("unlocker"),
            makeAddr("rootSetter"),
            block.timestamp + 9 days
        );
        vm.stopBroadcast();
        console.log("KAT Token address: ", address(katToken));
        console.log("MerkleMinter address: ", address(merkleMinter));
    }

    function deploy(
        address _admin,
        address _inflation_ben,
        address _unlocker,
        address _rootSetter,
        uint256 _unlockDelay
    ) public returns (KatToken katToken, MerkleMinter merkleMinter) {
        bytes32 salt = "funny text";
        address _merkleMinter = vm.computeCreate2Address(
            salt,
            keccak256(bytes.concat(type(MerkleMinter).creationCode, abi.encode(_unlockDelay, _unlocker, _rootSetter)))
        );
        // string memory name,
        // string memory symbol,
        // address inflation_admin,
        // address inflation_beneficiary,
        // address _merkleMinter
        katToken = new KatToken{salt: salt}("KatToken", "KAT", _admin, _inflation_ben, _merkleMinter);
        // uint256 _unlockTime
        // address _unlocker
        // address _rootSetter
        merkleMinter = new MerkleMinter{salt: salt}(_unlockDelay, _unlocker, _rootSetter);

        assert(address(merkleMinter) == _merkleMinter);
    }
}
