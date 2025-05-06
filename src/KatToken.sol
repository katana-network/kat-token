// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import {ERC20Permit, ERC20} from "dependencies/@openzeppelin-contracts-5.1.0/token/ERC20/extensions/ERC20Permit.sol";
import {PowUtil} from "./Powutil.sol";

contract KatToken is ERC20Permit {
    event InflationDistributed(address receiver, uint256 amount);
    event InflationChanged(uint256 oldValue, uint256 newValue);
    event MintCapacityDistributed(address sender, address receiver, uint256 amount);
    event RoleChangeStarted(address newHolder, bytes32 role);
    event RoleChangeCompleted(address newHolder, bytes32 role);

    // Roles
    // This role can set the inflation percentage
    bytes32 public constant INFLATION_ADMIN = keccak256("INFLATION_ADMIN");
    // Initial receiver of the inflated minting capacity, can distribute it away as needed
    bytes32 public constant INFLATION_BENEFICIARY = keccak256("INFLATION_BENEFICIARY");
    // Can unlock the token early, no relocking
    bytes32 public constant UNLOCKER = keccak256("UNLOCKER");
    // Can give and take the right to transfer during locking period
    bytes32 public constant LOCK_EXEMPTION_ADMIN = keccak256("LOCK_EXEMPTION_ADMIN");

    // All current role holder
    mapping(bytes32 => address) public roleHolder;
    // Potential new role holder, if they accept
    mapping(bytes32 => address) public pendingRoleHolder;

    // Inflation
    // Total token capacity after the last settlement
    uint256 public distributedSupplyCap;
    // Blocktime of last inflated mintCapacity distribution
    uint256 public lastMintCapacityIncrease;
    // Inflation Factor
    // Be careful when changing this, value needs to be set as the log of the expected inflation percentage
    // Example: yearly inflation of 2% needs an inflationFactor of log(1.02) = 0.028569152196770894e18
    // Don't forget the decimals, also take a look at the tests in Inflation.t.sol
    uint256 public inflationFactor;

    // Mint capacity distributed from inflation, also initial mint capacity
    mapping(address => uint256) public mintCapacity;

    // Lock
    // Time of the unlock, can't be changed, lock definitely opens after this
    uint256 public immutable unlockTime;
    // Overrides unlockTime to allow early unlocking, can't be used to lock again, also not required for time based unlocking
    bool public locked = true;

    // Addresses exempted from the lock, can transfer and transferFrom (only if both spender and from are exempted) during lock
    mapping(address => bool) lockExemption;

    modifier hasRole(bytes32 _role) {
        require(roleHolder[_role] == msg.sender, "Not role holder.");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _inflationAdmin,
        address _inflationBeneficiary,
        address _distributor,
        uint256 _unlockTime,
        address _unlocker,
        address _lockExemptionAdmin
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        require(bytes(_name).length != 0);
        require(bytes(_symbol).length != 0);
        require(_inflationAdmin != address(0));
        require(_inflationBeneficiary != address(0));
        require(_distributor != address(0));
        require(_unlockTime > block.timestamp);
        // Unlock at most 24 months in the future
        require(_unlockTime < block.timestamp + 24 * 30 days);
        require(_unlocker != address(0));
        require(_lockExemptionAdmin != address(0));

        // Initial cap is 10 billion
        uint256 initialDistribution = 10_000_000_000 * (10 ** decimals());
        mintCapacity[_distributor] = initialDistribution;
        distributedSupplyCap = initialDistribution;

        // set to sane default value
        lastMintCapacityIncrease = block.timestamp;
        // Set initial inflation to 0
        inflationFactor = 0;

        // Assign roles
        roleHolder[INFLATION_ADMIN] = _inflationAdmin;
        roleHolder[INFLATION_BENEFICIARY] = _inflationBeneficiary;
        roleHolder[UNLOCKER] = _unlocker;
        roleHolder[LOCK_EXEMPTION_ADMIN] = _lockExemptionAdmin;

        unlockTime = _unlockTime;
        // Allow transfers for initial token distributor
        lockExemption[_distributor] = true;
    }

    /**
     * Function to change the current holder of a role, can only be used by current role holder
     * To finalize the change the new holder needs to call acceptRole()
     */
    function changeRoleHolder(address _newRoleOwner, bytes32 _role) external hasRole(_role) {
        pendingRoleHolder[_role] = _newRoleOwner;
        emit RoleChangeStarted(_newRoleOwner, _role);
    }

    /**
     * Function to accept a role holder change proposal
     * Only the pending role holder can accept
     */
    function acceptRole(bytes32 _role) external {
        require(pendingRoleHolder[_role] == msg.sender, "Not new role holder.");
        roleHolder[_role] = pendingRoleHolder[_role];
        pendingRoleHolder[_role] = address(0);
        emit RoleChangeCompleted(roleHolder[_role], _role);
    }

    /**
     * Function to renounce the inflationAdmin role
     * This can't be reverted
     * Inflation can be not 0 and INFLATION_BENEFICIARY can still be changed
     */
    function renounceInflationAdmin() external hasRole(INFLATION_ADMIN) {
        require(pendingRoleHolder[INFLATION_ADMIN] == address(0), "Role transfer in progress.");
        roleHolder[INFLATION_ADMIN] = address(0);
    }

    /**
     * Function to renounce the inflationBeneficiary role
     * This can't be reverted
     * Can only happen once inflation is 0 and INFALTION_ADMIN is renounced
     */
    function renounceInflationBeneficiary() external hasRole(INFLATION_BENEFICIARY) {
        require(pendingRoleHolder[INFLATION_BENEFICIARY] == address(0), "Role transfer in progress.");
        require(inflationFactor == 0, "Inflation not zero.");
        // Can't be wrong, remove?
        require(roleHolder[INFLATION_ADMIN] == address(0), "Inflation admin not 0.");
        require(pendingRoleHolder[INFLATION_ADMIN] == address(0), "Role transfer in progress.");

        roleHolder[INFLATION_BENEFICIARY] = address(0);
        emit RoleChangeCompleted(address(0), INFLATION_BENEFICIARY);
    }

    /**
     * Unlocks the claim function early, afterwards contract can't be locked again
     * Can be used after unlock to clean unlocker variable
     */
    function unlockAndRenounceUnlocker() external hasRole(UNLOCKER) {
        locked = false;
        roleHolder[UNLOCKER] = address(0);
        pendingRoleHolder[UNLOCKER] = address(0);
    }

    /**
     * Renounces the LOCK_EXEMPTION_ADMIN
     * Can be used after unlock to clean LOCK_EXEMPTION_ADMIN variable
     * For full cleaning lockExemption needs to be manually emptied
     */
    function renounceLockExemptionAdmin() external hasRole(LOCK_EXEMPTION_ADMIN) {
        roleHolder[LOCK_EXEMPTION_ADMIN] = address(0);
        pendingRoleHolder[LOCK_EXEMPTION_ADMIN] = address(0);
    }

    /**
     * Returns true if either the unlock time has passed or a manual unlock has occurred
     */
    function isUnlocked() public view returns (bool) {
        // do a fail fast check on time first, then storage slot, this makes transfer cheap again after the time unlock
        return (block.timestamp > unlockTime) || !locked;
    }

    /**
     * Adds (or removes) an address to allow it to transfer during the lock period
     */
    function setLockExemption(address user) external hasRole(LOCK_EXEMPTION_ADMIN) {
        lockExemption[user] = !lockExemption[user];
    }

    /**
     * Mint within confines of mint capacity
     * @param to Receiver of the newly minted tokens
     * @param amount Amount to be minted
     */
    function mint(address to, uint256 amount) external {
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
    function changeInflation(uint256 value) external hasRole(INFLATION_ADMIN) {
        require(roleHolder[INFLATION_BENEFICIARY] != address(0), "No inflation beneficiary.");
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
        // Only used if inflation was distributed in same block, worth it?
        if (lastMintCapacityIncrease == block.timestamp) {
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
        address inflationBeneficiary = roleHolder[INFLATION_BENEFICIARY];
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
        if (isUnlocked()) {
            super._update(from, to, amount);
        }
        // Only allow transfer for lockExempted addresses
        // transferFrom only works if both approver and spender are whitelisted
        else if (lockExemption[from] && lockExemption[msg.sender]) {
            super._update(from, to, amount);
        } else if (from == address(0)) {
            super._update(from, to, amount);
        } else {
            revert("Token locked.");
        }
    }
}
