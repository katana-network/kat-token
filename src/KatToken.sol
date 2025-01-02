// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {ERC20Permit, ERC20} from "dependencies/@openzeppelin-contracts-5.1.0/token/ERC20/extensions/ERC20Permit.sol";
import {PowUtil} from "./Powutil.sol";

contract KatToken is ERC20Permit {
    // role management
    // minting is not a role, but intrinsic
    // This role can set the inflation to values between 0% and 3% per year
    bytes32 public constant INFLATION_ADMIN = keccak256("INFLATION_ADMIN");
    // Initial receiver of the inflated minting capacity, can distribute it away as needed
    bytes32 public constant INFLATION_BENEFICIARY = keccak256("INFLATION_BENEFICIARY");

    mapping(bytes32 => address) public roles;

    // cap after the last settlement
    uint256 distributedSupplyCap;
    // Blocktime of last inflated mintCapacity distribution
    uint256 lastMintCapacityIncrease;
    // Inflation Factor, only relevant 4 years after deployment
    uint256 public inflationFactor;
    // Maximum configurable inflation (3%)
    uint256 public constant MAX_INFLATION = 0.04264433740849369e18; // log2(1.03)

    address public immutable merkleMinter;
    mapping(address => uint256) public mintCapacity;

    // all these calcs ignore leap seconds or might be otherwise inaccurate, we assume this is good enough
    constructor(
        string memory name,
        string memory symbol,
        address inflation_admin,
        address inflation_beneficiary,
        address _merkleMinter
    ) ERC20(name, symbol) ERC20Permit(name) {
        // Initial cap is 10 billion
        uint256 initialDistribution = 10_000_000_000;
        // Give all to this contract so we can distribute afterwards
        mintCapacity[_merkleMinter] = initialDistribution;
        distributedSupplyCap = initialDistribution;
        // set to start of supply increase, 4 years after deployment
        lastMintCapacityIncrease = block.timestamp + 4 * 365 days + 1 days;

        // Assign roles
        roles[INFLATION_ADMIN] = inflation_admin;
        roles[INFLATION_BENEFICIARY] = inflation_beneficiary;

        // Set initial inflation after 4 years
        inflationFactor = 0.02856915219677089e18; // log2(1.02)

        merkleMinter = _merkleMinter;
    }

    function changeRole(address newOwner, bytes32 role) public {
        // Use 0xDead to disable role, careful, this can't be reverted
        require(newOwner != address(0x00), "Missing new owner.");
        require(msg.sender == roles[role], "Not role owner.");
        roles[role] = newOwner;
    }

    // No separate mint function, just mintTo self if needed
    function mintTo(address to, uint256 amount) public {
        require(mintCapacity[msg.sender] >= amount, "Not enough mint capacity.");
        mintCapacity[msg.sender] -= amount;
        _mint(to, amount);
    }

    // calc cap per the rule
    function cap() public view returns (uint256) {
        return distributedSupplyCap + _calcInflation();
    }

    function changeInflation(uint256 value) public {
        require(msg.sender == roles[INFLATION_ADMIN], "Not allowed.");
        require(value < MAX_INFLATION, "Inflation to large.");
        distributeInflation();
        inflationFactor = value;
    }

    function _calcInflation() internal view returns (uint256) {
        //calc total increase
        if (lastMintCapacityIncrease > block.timestamp) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - lastMintCapacityIncrease;
        uint256 supplyFactor = PowUtil.exp2((inflationFactor * timeElapsed) / 365 days);
        uint256 newCap = (supplyFactor * distributedSupplyCap) / 1e18;

        return newCap - distributedSupplyCap;
    }

    function distributeInflation() public {
        uint256 inflation = _calcInflation();
        distributedSupplyCap += inflation;
        // give increase to INFLATION_BENEFICIARY
        mintCapacity[roles[INFLATION_BENEFICIARY]] += inflation;
        // increase distributedSupplyCap
        if (block.timestamp > lastMintCapacityIncrease) {
            lastMintCapacityIncrease = block.timestamp;
        }
    }

    function distributeMintCapacity(address to, uint256 amount) public {
        require(to != address(0x00), "Sending to 0x00");
        require(mintCapacity[msg.sender] >= amount, "Not enough capacity.");
        mintCapacity[msg.sender] -= amount;
        mintCapacity[to] += amount;
    }
}
