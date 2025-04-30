// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import {ERC20Permit, ERC20} from "dependencies/@openzeppelin-contracts-5.1.0/token/ERC20/extensions/ERC20Permit.sol";
import {PowUtil} from "./Powutil.sol";

contract KatToken is ERC20Permit {
    event InflationDistributed(address receiver, uint256 amount);
    event InflationChanged(uint256 oldValue, uint256 newValue);
    event MintCapacityDistributed(address sender, address receiver, uint256 amount);
    event InflationAdminChanged(address newAdmin, bool pending);
    event InflationBeneficiaryChanged(address newBeneficiary, bool pending);

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
    uint256 public constant MAX_INFLATION = 0.042644337408493685e18; // log2(1.03)

    // Mint capacity distributed after the inflation starts
    mapping(address => uint256) public mintCapacity;

    uint256 public immutable unlockTime;
    bool public locked = true;
    address public unlocker;

    mapping(address => bool) lockExempt;
    address public lockExemptionAdmin;

    constructor(
        string memory _name,
        string memory _symbol,
        address _inflationAdmin,
        address _inflationBeneficiary,
        address _distributor,
        uint256 _unlockTime,
        address _unlocker,
        address lockExemptionAdmin
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        require(bytes(_name).length != 0);
        require(bytes(_symbol).length != 0);
        require(_inflationAdmin != address(0));
        require(_inflationBeneficiary != address(0));
        require(_distributor != address(0));
        require(_unlockTime > block.timestamp);
        // Unlock at most 24 months in the future
        require(_unlockTime < block.timestamp + 24 * 30 days);

        // Initial cap is 10 billion
        uint256 initialDistribution = 10_000_000_000 * (10 ** decimals());
        mintCapacity[_distributor] = initialDistribution;
        distributedSupplyCap = initialDistribution;

        // set to start of supply increase, 4 years after deployment
        // all these calcs ignore leap seconds or might be otherwise slightly inaccurate, we assume this is good enough
        lastMintCapacityIncrease = block.timestamp + 4 * 365 days + 1 days;

        // Assign roles
        inflationAdmin = _inflationAdmin;
        inflationBeneficiary = _inflationBeneficiary;

        // Set initial inflation after 4 years
        inflationFactor = 0.028569152196770894e18; // log2(1.02)

        unlockTime = _unlockTime;
        unlocker = _unlocker;
        lockExempt[_distributor] = true;
        lockExemptionAdmin = lockExemptionAdmin;
    }

    /**
     * Function to change the current owner of the inflationAdmin role
     * To finalize the change the new owner needs to call acceptInflationAdmin()
     * @param newInflationAdmin address that will hold the role
     */
    function changeInflationAdmin(address newInflationAdmin) external {
        require(msg.sender == inflationAdmin, "Not role owner.");
        pendingInflationAdmin = newInflationAdmin;
        emit InflationAdminChanged(newInflationAdmin, true);
    }

    /**
     * Function to accept the inflationAdmin role
     */
    function acceptInflationAdmin() external {
        require(msg.sender == pendingInflationAdmin, "Not new role owner.");
        inflationAdmin = pendingInflationAdmin;
        pendingInflationAdmin = address(0);
        emit InflationAdminChanged(inflationAdmin, false);
    }

    /**
     * Function to renounce the inflationAdmin role
     * This can't be reverted
     */
    function renounceInflationAdmin() external {
        require(msg.sender == inflationAdmin, "Not role owner.");
        require(pendingInflationAdmin == address(0), "Role transfer in progress.");
        inflationAdmin = address(0);
        emit InflationAdminChanged(address(0), false);
    }

    /**
     * Function to change the current owner of the inflationBeneficiary role
     * To finalize the change the new owner needs to call acceptInflationBeneficiary()
     * @param newInflationBeneficiary address that will hold the role
     */
    function changeInflationBeneficiary(address newInflationBeneficiary) external {
        require(msg.sender == inflationBeneficiary, "Not role owner.");
        pendingInflationBeneficiary = newInflationBeneficiary;
        emit InflationBeneficiaryChanged(newInflationBeneficiary, true);
    }

    /**
     * Function to accept the inflationBeneficiary role
     */
    function acceptInflationBeneficiary() external {
        require(msg.sender == pendingInflationBeneficiary, "Not new role owner.");
        inflationBeneficiary = pendingInflationBeneficiary;
        pendingInflationBeneficiary = address(0);
        emit InflationBeneficiaryChanged(inflationBeneficiary, false);
    }

    /**
     * Function to renounce the inflationBeneficiary role
     * This can't be reverted
     */
    function renounceInflationBeneficiary() external {
        require(msg.sender == inflationBeneficiary, "Not role owner.");
        require(pendingInflationBeneficiary == address(0), "Role transfer in progress.");
        require(inflationFactor == 0, "Inflation not zero.");
        inflationBeneficiary = address(0);
        emit InflationBeneficiaryChanged(address(0), false);
    }

    /**
     * Unlocks the claim function early, afterwards contract can't be locked again
     * Can be used after unlock to clean unlocker variable
     */
    function unlockAndRenounceUnlocker() external {
        require(msg.sender == unlocker, "Not unlocker.");
        locked = false;
        unlocker = address(0);
    }

    function isLocked() public view returns (bool) {
        // do a fail fast check on time first, then storage slot, this makes transfer cheap again after the time unlock
        return (block.timestamp > unlockTime) || !locked;
    }

    function setWhitelist(address user) external {
        require(msg.sender == lockExemptionAdmin, "Not lockExemption admin.");
        lockExempt[user] = !lockExempt[user];
    }

    /**
     * Mint within confines of mint capacity
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
        require(msg.sender == inflationAdmin, "Not role owner.");
        require(value <= MAX_INFLATION, "Inflation too large.");
        require(inflationBeneficiary != address(0), "No inflation beneficiary.");
        distributeInflation();
        uint256 oldValue = inflationFactor;
        inflationFactor = value;
        emit InflationChanged(oldValue, value);
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
        // Check if we are in the before inflation period so we don't override lastMintCapacityIncrease
        if (lastMintCapacityIncrease > block.timestamp) {
            return;
        }
        uint256 inflation = _calcInflation();
        distributedSupplyCap += inflation;
        mintCapacity[inflationBeneficiary] += inflation;
        lastMintCapacityIncrease = block.timestamp;
        emit InflationDistributed(inflationBeneficiary, inflation);
    }

    /**
     * Distributes mint capacity to a minter
     * @param to Receiver of the mint capacity
     * @param amount Amount to be added as mint capacity
     */
    function distributeMintCapacity(address to, uint256 amount) external {
        require(to != address(0), "Sending to 0 address");
        require(mintCapacity[msg.sender] >= amount, "Not enough mint capacity.");
        mintCapacity[msg.sender] -= amount;
        mintCapacity[to] += amount;
        emit MintCapacityDistributed(msg.sender, to, amount);
    }

    /**
     * Override _update to check if lock is still in place
     * Additionally check if user is allowed early transfers
     */
    function _update(address from, address to, uint256 amount) internal override {
        if (isLocked()) {
            // Only allow transfer for lockExempted addresses
            // transferFrom only works if both approver and spender are whitelisted
            if (!(lockExempt[from] && lockExempt[msg.sender])) {
                revert("Token locked.");
            }
        }
        super._update(from, to, amount);
    }
}
