import "./exp2-summary.spec";

methods {
    function inflationAdmin() external returns (address) envfree;
    function pendingInflationAdmin() external returns (address) envfree;
    function inflationBeneficiary() external returns (address) envfree;
    function pendingInflationBeneficiary() external returns (address) envfree;
    function inflationFactor() external returns (uint256) envfree;
    function MAX_INFLATION() external returns (uint256) envfree;
    function merkleMinter() external returns (address) envfree;
    function mintCapacity(address) external returns (uint256) envfree;
    
    //harness methods declared envfree
    function get_lastMintCapacityIncrease() external returns (uint256) envfree;
    function get_distributedSupplyCap() external returns (uint256) envfree;
    
    function ERC20._mint(address to, uint256 amount) internal
        => _mintCVL(to, amount);
    
    //MerkleProof
    function _.verify(bytes32[], bytes32, bytes32) external => NONDET DELETE;

    function _.eip712Domain() external => NONDET DELETE;
}

rule integrityOfchangeInflationAdmin(env e) {
    address oldOwner = inflationAdmin();
    address newOwner;

    changeInflationAdmin(e, newOwner);

    assert(e.msg.sender == oldOwner);
    assert(pendingInflationAdmin() == newOwner);
}

rule integrityOfchangeInflationBeneficiary(env e) {
    address oldOwner = inflationBeneficiary();
    address newOwner;

    changeInflationBeneficiary(e, newOwner);

    assert(e.msg.sender == oldOwner);
    assert(pendingInflationBeneficiary() == newOwner);
}

rule lastMintCapacityIncreaseNeverDecreases(env e, method f)
{
    uint256 lastMintCapacityIncrease_pre = get_lastMintCapacityIncrease();

    calldataarg args;
    f(e, args);
    uint256 lastMintCapacityIncrease_post = get_lastMintCapacityIncrease();
    assert lastMintCapacityIncrease_post >= lastMintCapacityIncrease_pre;
}

rule distributedSupplyCapNeverDecreases(env e, method f)
{
    uint256 distributedSupplyCap_pre = get_distributedSupplyCap();

    calldataarg args;
    f(e, args);
    uint256 distributedSupplyCap_post = get_distributedSupplyCap();
    assert distributedSupplyCap_post >= distributedSupplyCap_pre;
}

rule integrityOfDistributeMintCapacity(env e) {
    address to;
    uint256 amount;

    uint256 ownCapacityBefore = mintCapacity(e.msg.sender);
    uint256 toCapacityBefore = mintCapacity(to);

    distributeMintCapacity(e, to, amount);

    uint256 ownCapacityAfter = mintCapacity(e.msg.sender);
    uint256 toCapacityAfter = mintCapacity(to);

    assert(ownCapacityBefore >= amount);
    assert(ownCapacityBefore + toCapacityBefore == ownCapacityAfter + toCapacityAfter);
}

ghost mapping(address => mathint) mintedTo;
ghost mathint totalMintCapacityChange;
ghost mathint totalMintedChange;

function _mintCVL(address to, uint256 amount)
{
    mintedTo[to] = mintedTo[to] + amount;
    totalMintedChange = totalMintedChange + amount;
}

hook Sstore KatTokenHarness.mintCapacity[KEY address user] uint256 newCap (uint256 oldCap) {
    totalMintCapacityChange = totalMintCapacityChange + newCap - oldCap;
}

function initGhosts()
{
    totalMintCapacityChange = 0;
    totalMintedChange = 0;
}

rule mintCapacityPlusMintedNeverDecrease(env e, method f)
{
    initGhosts();
    calldataarg args;
    f(e, args);
    assert totalMintedChange + totalMintCapacityChange >= 0;
}

rule mintCapacityPlusMintedEqualsDistributedSupplyCap(env e, method f)
{
    initGhosts();
    uint256 distributedSupplyCap_pre = get_distributedSupplyCap();
    calldataarg args;
    f(e, args);
    uint256 distributedSupplyCap_post = get_distributedSupplyCap();
    assert distributedSupplyCap_post - distributedSupplyCap_pre ==
        totalMintedChange + totalMintCapacityChange;
}

/**
 * The inflation factor is bounded by MAX_INFLATION.
 */
invariant inflationFactorIsBounded()
    inflationFactor() <= MAX_INFLATION();

rule changeInflation_revertConditions(env e)
{
    uint256 value;
    changeInflation@withrevert(e, value);
    bool reverted = lastReverted;
    assert lastReverted =>
        e.msg.sender != inflationAdmin() ||
        e.msg.value != 0 ||
        value > MAX_INFLATION();
}

rule integrityOfRenounceInflationAdmin(env e, method f)
{
    address admin_pre = inflationAdmin();
    renounceInflationAdmin(e);
    address admin_post = inflationAdmin();

    assert admin_pre == e.msg.sender;
    assert admin_post == 0;
}

rule integrityOfRenounceInflationBeneficiary(env e, method f)
{
    address beneficiary_pre = inflationBeneficiary();
    renounceInflationBeneficiary(e);
    address beneficiary_post = inflationBeneficiary();

    assert beneficiary_pre == e.msg.sender;
    assert beneficiary_post == 0;
}

// once renounceInflationAdmin is performed, the inflationAdmin will always be zero
// we've proved that renounceInflationAdmin changes it to zero so here we just prove
// that it cannot change from 0 to non-zero
rule inflationAdminValueChange(env e, method f)
{
    address admin_pre = inflationAdmin();
    require e.msg.sender != 0;
    calldataarg args;
    f(e, args);
    address admin_post = inflationAdmin();
    assert admin_pre == 0 => admin_post == 0;
}

// once renounceInflationBeneficiary is performed, the inflationBeneficiary will always be zero
// we've proved that renounceInflationBeneficiary changes it to zero so here we just prove
// that it cannot change from 0 to non-zero
rule inflationBeneficiaryValueChange(env e, method f)
{
    address beneficiary_pre = inflationBeneficiary();
    require e.msg.sender != 0;
    calldataarg args;
    f(e, args);
    address beneficiary_post = inflationBeneficiary();
    assert beneficiary_pre == 0 => beneficiary_post == 0;
}

invariant mintCapacityOfZeroIsZero()
    mintCapacity(0) == 0
    { preserved
        with (env e) { require e.msg.sender != 0; }
    }