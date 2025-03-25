import "./exp2-summary_stronger.spec";

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
    
    //MerkleProof
    function _.verify(bytes32[], bytes32, bytes32) external => NONDET DELETE;

    function _.eip712Domain() external => NONDET DELETE;
}

/**
 * The inflation factor is bounded by MAX_INFLATION.
 */
invariant inflationFactorIsBounded()
    inflationFactor() <= MAX_INFLATION();

rule changeInflation_revertConditions(env e)
{
    requireInvariant inflationFactorIsBounded();
    require mintCapacity(inflationBeneficiary()) <= get_distributedSupplyCap(); // implied by mintCapacityPlusMintedEqualsDistributedSupplyCap
    uint256 value;
    changeInflation@withrevert(e, value);
    bool reverted = lastReverted;
    assert reverted =>
        e.msg.sender != inflationAdmin() ||
        e.msg.value != 0 ||
        inflationBeneficiary() == 0 ||
        value > MAX_INFLATION() ||
        e.block.timestamp > get_lastMintCapacityIncrease() + 100 *365 *24 *60 *60 || // unreasonably high, more than 100 years between calls to distributeInflation
        get_distributedSupplyCap() > 10^35; // unreasonably high, causing an overflow. With 3% p.y. the inflation factor can get up to 1.03^100 < 20 while the initial distribution is 1e28
}
