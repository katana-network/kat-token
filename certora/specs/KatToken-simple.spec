methods {
    function inflationAdmin() external returns (address) envfree;
    function inflationBeneficiary() external returns (address) envfree;
    function inflationFactor() external returns (uint256) envfree;
    function MAX_INFLATION() external returns (uint256) envfree;
    function merkleMinter() external returns (address) envfree;
    function mintCapacity(address) external returns (uint256) envfree;
    
    //harness methods declared envfree
    function get_lastMintCapacityIncrease() external returns (uint256) envfree;
    function get_distributedSupplyCap() external returns (uint256) envfree;
    
    
    //MerkleProof
    function _.verify(bytes32[] memory, bytes32, bytes32) internal => NONDET;
}

rule integrityOfchangeInflationAdmin(env e) {
    address oldOwner = inflationAdmin();
    address newOwner;

    changeInflationAdmin(e, newOwner);

    assert(e.msg.sender == oldOwner);
    assert(inflationAdmin() == newOwner);
}

rule integrityOfchangeInflationBeneficiary(env e) {
    address oldOwner = inflationBeneficiary();
    address newOwner;

    changeInflationBeneficiary(e, newOwner);

    assert(e.msg.sender == oldOwner);
    assert(inflationBeneficiary() == newOwner);
}

rule lastMintCapacityIncreaseDeverDecreases(env e, method f)
{
    uint256 lastMintCapacityIncrease_pre = get_lastMintCapacityIncrease();

    calldataarg args;
    f(e, args);
    uint256 lastMintCapacityIncrease_post = get_lastMintCapacityIncrease();
    assert lastMintCapacityIncrease_post >= lastMintCapacityIncrease_pre;
}

//mintCapacity[x] <= distributedSupplyCap
// not an inductive property :( we need to use the equality
// lets get rid of this. it will be in implied by the quality property anyway
invariant mintCapacityLessThanDistributedSupplyCap(address a)
    mintCapacity(a) <= get_distributedSupplyCap();

rule canOnlySendAvailableMintCapacity() {
    env e;
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
