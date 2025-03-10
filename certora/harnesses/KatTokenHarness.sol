// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;
import {KatToken} from "src/KatToken.sol";

contract KatTokenHarness is KatToken {
    constructor(
        string memory _name,
        string memory _symbol,
        address _inflationAdmin,
        address _inflationBeneficiary,
        address _merkleMinter
    ) KatToken(_name, _symbol, _inflationAdmin, _inflationBeneficiary, _merkleMinter) 
    {
    }

    function get_lastMintCapacityIncrease() public view returns (uint256) {
        return lastMintCapacityIncrease;
    }

    function get_distributedSupplyCap() public view returns (uint256) {
        return distributedSupplyCap;
    }

}
