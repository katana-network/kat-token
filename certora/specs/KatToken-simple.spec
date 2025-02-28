rule onlyAdminCanChangeAdmin() {
    env e;
    address oldOwner = inflationAdmin(e);
    address newOwner;

    changeInflationAdmin(e, newOwner);

    assert(e.msg.sender == oldOwner);
    assert(inflationAdmin(e) == newOwner);
}

rule canOnlySendAvailableMintCapacity() {
    env e;
    address to;
    uint256 amount;

    uint256 ownCapacityBefore = mintCapacity(e, e.msg.sender);
    uint256 toCapacityBefore = mintCapacity(e, to);

    distributeMintCapacity(e, to, amount);


    uint256 ownCapacityAfter = mintCapacity(e, e.msg.sender);
    uint256 toCapacityAfter = mintCapacity(e, to);

    assert(ownCapacityBefore >= amount);
    assert(ownCapacityBefore + toCapacityBefore == ownCapacityAfter + toCapacityAfter);
}
