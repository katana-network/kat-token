methods {
    function root() external returns (bytes32) envfree;
    function rootSetter() external returns (address) envfree;
    function katToken() external returns (address) envfree;
    function unlockTime() external returns (uint256) envfree;
    function locked() external returns (bool) envfree;
    function unlocker() external returns (address) envfree;
    function indexIsClaimed(uint256 index) external returns (bool) envfree;

    //MerkleProof
    function _.verify(bytes32[], bytes32, bytes32) external => NONDET DELETE;

    function _.eip712Domain() external => NONDET DELETE;
}

// Once the claiming becomes possible, the contract will never go to a locked state again
rule onceActivatedItStaysActive(env e1, env e2, method f)
{
    require e1.block.timestamp <= e2.block.timestamp;
    bool active_pre = (e1.block.timestamp > unlockTime()) || !locked();

    calldataarg args;
    f(e1, args);
    bool active_post = (e2.block.timestamp > unlockTime()) || !locked();
    assert active_pre => active_post;
}

rule integrityOfInit() {
    env e;
    bytes32 _root;
    address _katToken;

    address rootSetterBefore = rootSetter();

    init(e, _root, _katToken);

    assert(e.msg.sender == rootSetterBefore);
    assert(root() == _root);
    assert(katToken() == _katToken);
}

rule integrityOfUnlockAndRenounceUnlocker(env e) {
    address currentUnlocker = unlocker();
    unlockAndRenounceUnlocker(e);

    assert(e.msg.sender == currentUnlocker);
    assert(locked() == false);
    assert(unlocker() == 0);
}

rule canOnlyClaimWhenNotLocked(env e) 
{
    bytes32[] proof; uint256 index; uint256 amount; address receiver;
    claimKatToken(e, proof, index, amount, receiver);

    assert(e.block.timestamp > unlockTime() || !locked());
}

rule katTokenCannotBeChangedOutsideInit(env e, method f)
    filtered { f -> f.selector != sig:init(bytes32, address).selector }
    // init is the only method that can set the katToken
{
    address token_pre = katToken();
    calldataarg args;
    f(e, args);
    address token_post = katToken();
    assert token_pre == token_post;
}

rule rootCannotBeChangedOutsideInit(env e, method f)
    filtered { f -> f.selector != sig:init(bytes32, address).selector }
    // init is the only method that can set the root
{
    bytes32 root_pre = root();
    calldataarg args;
    f(e, args);
    bytes32 root_post = root();
    assert root_pre == root_post;
}

//locked can only change from true -> false or stay the same
rule lockedValueChange(env e, method f)
{
    bool locked_pre = locked();
    calldataarg args;
    f(e, args);
    bool locked_post = locked();
    assert locked_post => locked_pre;   // if true after then if was already true before, i.e. it cannot go from false to true
}

//rootSetter can only change from x -> 0 or stay the same
rule rootSetterValueChange(env e, method f)
{
    address rootSetter_pre = rootSetter();
    calldataarg args;
    f(e, args);
    address rootSetter_post = rootSetter();
    assert rootSetter_post == rootSetter_pre || rootSetter_post == 0;
}

// indexIsClaimed can only change false -> true or stay the same
rule indexIsClaimedValueChange(env e, method f)
{
    uint256 index;
    bool claimed_pre = indexIsClaimed(index);
    calldataarg args;
    f(e, args);
    bool claimed_post = indexIsClaimed(index);
    assert claimed_pre => claimed_post;
}

// indexIsClaimed == true => claimKatToken(..,index) will revert
rule cannotClaimTheIndexTwice(env e)
{
    uint256 index;
    bool isClaimed = indexIsClaimed(index);
    bytes32[] proof; uint256 amount; address receiver;
    
    claimKatToken@withrevert(e, proof, index, amount, receiver);
    bool reverted = lastReverted;

    assert isClaimed => reverted;
}