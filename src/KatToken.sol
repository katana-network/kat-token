// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import {ERC20Permit, ERC20} from "dependencies/@openzeppelin-contracts-5.1.0/token/ERC20/extensions/ERC20Permit.sol";
import {PowUtil} from "./Powutil.sol";

contract KatToken is ERC20Permit {
    // This role can set the inflation to values between 0% and 3% per year
    address public inflationAdmin;
    address public pendingInflationAdmin;

    // Initial receiver of the inflated minting capacity, can distribute it away as needed
    address public inflationBeneficiary;
    address public pendingInflationBeneficiary;

    // cap after the last settlement
    uint256 public distributedSupplyCap;
    // Blocktime of last inflated mintCapacity distribution
    uint256 public lastMintCapacityIncrease;
    // Inflation Factor, only relevant 4 years after deployment
    uint256 public inflationFactor;
    // Maximum configurable inflation (3% annually)
    uint256 public constant MAX_INFLATION = 0.04264433740849369e18; // log2(1.03)

    // Address of the merkle minter, that holds all initial mint capacity
    address public immutable merkleMinter;
    // Mint capacity distributed after the inflation starts
    mapping(address => uint256) public mintCapacity;

    constructor(
        string memory _name,
        string memory _symbol,
        address _inflationAdmin,
        address _inflationBeneficiary,
        address _merkleMinter
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        require(bytes(_name).length != 0);
        require(bytes(_symbol).length != 0);
        require(_inflationAdmin != address(0));
        require(_inflationBeneficiary != address(0));
        require(_merkleMinter != address(0));

        // Initial cap is 10 billion
        uint256 initialDistribution = 10_000_000_000 * 10 ^ decimals();
        mintCapacity[_merkleMinter] = initialDistribution;
        distributedSupplyCap = initialDistribution;

        // set to start of supply increase, 4 years after deployment
        // all these calcs ignore leap seconds or might be otherwise slightly inaccurate, we assume this is good enough
        lastMintCapacityIncrease = block.timestamp + 4 * 365 days + 1 days;

        // Assign roles
        inflationAdmin = _inflationAdmin;
        inflationBeneficiary = _inflationBeneficiary;

        // Set initial inflation after 4 years
        inflationFactor = 0.02856915219677089e18; // log2(1.02)

        merkleMinter = _merkleMinter;
    }

    /**
     * Function to change the current owner of the inflationAdmin role
     * To finalize the change the new owner needs to call acceptInflationAdmin()
     * @param newInflationAdmin address that will hold the role
     */
    function changeInflationAdmin(address newInflationAdmin) external {
        require(msg.sender == inflationAdmin, "Not role owner.");
        pendingInflationAdmin = newInflationAdmin;
    }

    /**
     * Function to accept the inflationAdmin role
     */
    function acceptInflationAdmin() external {
        require(msg.sender == pendingInflationAdmin, "Not new role owner.");
        inflationAdmin = pendingInflationAdmin;
        pendingInflationAdmin = address(0);
    }

    /**
     * Function to renounce the inflationAdmin role
     * This can't be reverted
     */
    function renounceInflationAdmin() external {
        require(msg.sender == inflationAdmin, "Not role owner.");
        inflationAdmin = address(0);
    }

    /**
     * Function to change the current owner of the inflationBeneficiary role
     * To finalize the change the new owner needs to call acceptInflationBeneficiary()
     * @param newInflationBeneficiary address that will hold the role
     */
    function changeInflationBeneficiary(address newInflationBeneficiary) external {
        require(msg.sender == inflationBeneficiary, "Not role owner.");
        pendingInflationBeneficiary = newInflationBeneficiary;
    }

    /**
     * Function to accept the inflationBeneficiary role
     */
    function acceptInflationBeneficiary() external {
        require(msg.sender == pendingInflationBeneficiary, "Not new role owner.");
        inflationBeneficiary = pendingInflationBeneficiary;
        pendingInflationBeneficiary = address(0);
    }

    /**
     * Function to renounce the inflationBeneficiary role
     * This can't be reverted
     */
    function renounceInflationBeneficiary() external {
        require(msg.sender == inflationBeneficiary, "Not role owner.");
        inflationBeneficiary = address(0);
    }

    /**
     * No separate mint function, just mintTo self if needed
     * @param to Receiver of the newly minted tokens
     * @param amount Amount to be minted
     */
    function mintTo(address to, uint256 amount) external {
        require(mintCapacity[msg.sender] >= amount, "Not enough mint capacity.");
        mintCapacity[msg.sender] -= amount;
        _mint(to, amount);
    }

    /**
     * Calculates the current total cap of the token.
     * Already minted and not yet minted token amounts add up to this value
     * @return The current total token cap
     */
    function cap() external view returns (uint256) {
        return distributedSupplyCap + _calcInflation();
    }

    /**
     * Sets a new inflation factor starting immediately.
     * @dev Inflation until now will get distributed immediately using the old inflation factor
     * @dev only callable by the current INFLATION_ADMIN
     * @param value The new inflation factor
     */
    function changeInflation(uint256 value) external {
        require(msg.sender == inflationAdmin, "Not allowed.");
        require(value < MAX_INFLATION, "Inflation too large.");
        distributeInflation();
        inflationFactor = value;
    }

    /**
     * Calculates the inflation since the last distribution till now, using the current inflation factor
     * @return The unrealized inflation since the last realization
     */
    function _calcInflation() internal view returns (uint256) {
        if (lastMintCapacityIncrease > block.timestamp) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - lastMintCapacityIncrease;
        uint256 supplyFactor = PowUtil.exp2((inflationFactor * timeElapsed) / 365 days);
        uint256 newCap = (supplyFactor * distributedSupplyCap) / 1e18;
        return newCap - distributedSupplyCap;
    }

    /**
     * Fully realizes newly available inflation as mint capacity to the INFLATION_BENEFICIARY
     */
    function distributeInflation() public {
        uint256 inflation = _calcInflation();
        distributedSupplyCap += inflation;
        // give increase to INFLATION_BENEFICIARY
        mintCapacity[inflationBeneficiary] += inflation;
        // increase distributedSupplyCap
        if (block.timestamp > lastMintCapacityIncrease) {
            lastMintCapacityIncrease = block.timestamp;
        }
    }

    /**
     * Distributes mint capacity to a minter
     * @param to Receiver of the mint capacity
     * @param amount Amount to be added as mint capacity
     */
    function distributeMintCapacity(address to, uint256 amount) external {
        require(to != address(0), "Sending to 0 address");
        require(mintCapacity[msg.sender] >= amount, "Not enough capacity.");
        mintCapacity[msg.sender] -= amount;
        mintCapacity[to] += amount;
    }
}
