import "./exp2-summary.spec";

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
    
    function ERC20._mint(address to, uint256 amount) internal
        => _mintCVL(to, amount);
    
    //MerkleProof
    function _.verify(bytes32[] memory, bytes32, bytes32) external => NONDET DELETE;

    function _.eip712Domain() external => NONDET DELETE;
}

rule integrityOfchangeInflationAdmin(env e) {
    address oldOwner = inflationAdmin();
    address newOwner;

    changeInflationAdmin(e, newOwner);
    acceptInflationAdmin(e);

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

rule distributedSupplyCapDeverDecreases(env e, method f)
{
    uint256 distributedSupplyCap_pre = get_distributedSupplyCap();

    calldataarg args;
    f(e, args);
    uint256 distributedSupplyCap_post = get_distributedSupplyCap();
    assert distributedSupplyCap_post >= distributedSupplyCap_pre;
}

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
