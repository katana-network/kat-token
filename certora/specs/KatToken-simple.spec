methods {
    function inflationAdmin() external returns (address) envfree;
    function inflationBeneficiary() external returns (address) envfree;
    function inflationFactor() external returns (uint256) envfree;
    function MAX_INFLATION() external returns (uint256) envfree;
    function merkleMinter() external returns (address) envfree;
    function mintCapacity(address) external returns (uint256) envfree;
}

rule onlyAdminCanChangeAdmin() {
    env e;
    address oldOwner = inflationAdmin();
    address newOwner;

    changeInflationAdmin(e, newOwner);
    acceptInflationAdmin(e);

    assert(e.msg.sender == oldOwner);
    assert(inflationAdmin() == newOwner);
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
