methods {
    function root() external returns (bytes32) envfree;
    function rootSetter() external returns (address) envfree;
    function katToken() external returns (address) envfree;
    function unlockTime() external returns (uint256) envfree;
    function locked() external returns (bool) envfree;
    function unlocker() external returns (address) envfree;
}

rule integrityOfInit() {
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

rule integrityOfUnlock(env e) {
    address currentUnlocker = unlocker();
    unlock(e);

    assert(e.msg.sender == currentUnlocker);
    assert(locked() == false);
    assert(unlocker() == 0);
}

rule canOnlyClaimWhenNotLocked(env e) 
{
    bytes32[] proof; uint256 amount; address receiver;
    claimKatToken(e, proof, amount, receiver);

    assert(e.block.timestamp > unlockTime() || !locked());
}

rule canOnlyClaimWhenNotLocked_nontrivial(env e) 
{
    bytes32[] proof; uint256 amount; address receiver;
    require(proof.length > 0);

    claimKatToken(e, proof, amount, receiver);
    assert(e.block.timestamp > unlockTime() || !locked());
}

rule katTokenCannotBeChanged(env e, method f)
    filtered { f -> f.selector != sig:init(bytes32, address).selector }
    // init is the only method that can set the katToken
{
    address token_pre = katToken();
    calldataarg args;
    f(e, args);
    address token_post = katToken();
    assert token_pre == token_post;
}

//ocked can only change from true -> false
rule lockedValueChange(env e, method f)
{
    bool locked_pre = locked();
    calldataarg args;
    f(e, args);
    bool locked_post = locked();
    assert locked_post => locked_pre;   // if true after then if was already true before, i.e. it cannot go from false to true
}

//rootSetter can only change from x -> 0
rule rootSetterValueChange(env e, method f)
{
    address rootSetter_pre = rootSetter();
    calldataarg args;
    f(e, args);
    address rootSetter_post = rootSetter();
    assert rootSetter_post == rootSetter_pre || rootSetter_post == 0;
}
