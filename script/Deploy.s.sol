// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script, console} from "dependencies/forge-std-1.9.4/src/Script.sol";
import {KatToken} from "../src/KatToken.sol";

contract DeployScript is Script {
    string constant tokenName = "Katana Network Token";
    string constant tokenSymbol = "KAT";

    bytes32 constant salt = "funny text";
    address dummyInflationAdmin = makeAddr("inflation_admin");
    address dummyInflationBen = makeAddr("inflation_ben");
    address dummyMerkleMinter = makeAddr("inflation_admin");
    address dummyUnlocker = makeAddr("unlocker");
    address dummyLockExmeptionAdmin = makeAddr("lock_exemption_admin");
    address dummyDistributor = makeAddr("distributor");
    uint256 dummyUnlockTime = block.timestamp + 9 days;

    function run() public {
        address _inflationAdmin = vm.envAddress("INFLATION_ADMIN");
        address _inflationBen = vm.envAddress("INFLATION_BENEFICIARY");
        address _unlocker = vm.envAddress("UNLOCKER");
        uint256 _unlockTime = vm.envUint("UNLOCKTIME");
        address _lockExemptionAdmin = vm.envAddress("LOCK_EXEMPTION_ADMIN");
        address _distributor = vm.envAddress("DISTRIBUTOR");

        KatToken katToken =
            deploy(_inflationAdmin, _inflationBen, _distributor, _unlockTime, _unlocker, _lockExemptionAdmin);
        console.log("KAT token address: ", address(katToken));
    }

    function deploy(
        address _inflationAdmin,
        address _inflationBen,
        address _unlocker,
        uint256 _unlockTime,
        address _lockExemptionAdmin,
        address _distributor
    ) public returns (KatToken katToken) {
        // string memory _name,
        // string memory _symbol,
        // address _inflation_admin,
        // address _inflation_beneficiary,
        // address _distributor,
        // uint256 _unlockTime,
        // address _unlocker,
        // address _lockExemptionAdmin
        katToken = new KatToken{salt: salt}(
            tokenName,
            tokenSymbol,
            _inflationAdmin,
            _inflationBen,
            _distributor,
            _unlockTime,
            _unlocker,
            _lockExemptionAdmin
        );
    }

    function deployDummyToken() public returns (KatToken katToken) {
        return deploy(
            dummyInflationAdmin,
            dummyInflationBen,
            dummyDistributor,
            dummyUnlockTime,
            dummyUnlocker,
            dummyLockExmeptionAdmin
        );
    }
}
