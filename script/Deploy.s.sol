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
    address dummyUnlocker = makeAddr("unlocker");
    address dummyLockExemptionAdmin = makeAddr("lock_exemption_admin");
    address dummyDistributor = makeAddr("distributor");
    uint256 dummyUnlockTime = block.timestamp + 9 days;

    KatToken scriptDeployedToken;

    function run() public {
        address _inflationAdmin = vm.envAddress("INFLATION_ADMIN");
        require(_inflationAdmin != address(0), "Missing INFLATION_ADMIN");
        console.log("Using INFLATION_ADMIN:", _inflationAdmin);

        address _inflationBen = vm.envAddress("INFLATION_BENEFICIARY");
        require(_inflationBen != address(0), "Missing INFLATION_BENEFICIARY");
        console.log("Using INFLATION_BENEFICIARY:", _inflationBen);

        address _unlocker = vm.envAddress("UNLOCKER");
        require(_unlocker != address(0), "Missing UNLOCKER");
        console.log("Using UNLOCKER:", _unlocker);

        uint256 _unlockTime = vm.envUint("UNLOCKTIME");
        require(_unlockTime != 0, "Missing UNLOCKTIME");
        console.log("Using UNLOCKTIME:", _unlockTime);

        address _lockExemptionAdmin = vm.envAddress("LOCK_EXEMPTION_ADMIN");
        require(_lockExemptionAdmin != address(0), "Missing LOCK_EXEMPTION_ADMIN");
        console.log("Using LOCK_EXEMPTION_ADMIN:", _lockExemptionAdmin);

        address _distributor = vm.envAddress("DISTRIBUTOR");
        require(_distributor != address(0), "Missing DISTRIBUTOR");
        console.log("Using DISTRIBUTOR:", _distributor);

        console.log("------------DEPLOYING------------");

        scriptDeployedToken =
            deploy(_inflationAdmin, _inflationBen, _distributor, _unlockTime, _unlocker, _lockExemptionAdmin);
        console.log("KAT token address: ", address(scriptDeployedToken));
    }

    function deploy(
        address _inflationAdmin,
        address _inflationBen,
        address _distributor,
        uint256 _unlockTime,
        address _unlocker,
        address _lockExemptionAdmin
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
            dummyLockExemptionAdmin
        );
    }
}
