rule onlyRootCanInit() {
    env e;
    bytes32 _root;
    address _katToken;

    address rootBefore = rootSetter();

    init(e, _root, _katToken);

    assert(e.msg.sender == rootBefore);
    assert(root() == _root);
    assert(rootSetter() == 0);
    assert(katToken() == _katToken);
}

rule canOnlyClaimWhenNotLocked() {
    env e;

    bytes32[] proof;
    uint256 amount;
    address receiver;

    claimKatToken(e, proof, amount, receiver);

    assert(e.block.timestamp >= unlockTime());
    assert(!locked());
}