/**
 * Check properties on the actual implementation here.
 */

using KatToken as KatToken;

methods {
    function exp2(uint256 x) external returns (uint256) envfree;

    function KatToken.inflationFactor() external returns (uint256) envfree;
    function KatToken.MAX_INFLATION() external returns (uint256) envfree;
}

definition ONE18() returns uint256 =  1000000000000000000;
definition days(uint256 d) returns uint256 = assert_uint256(d * 60 * 60 * 24);

/**
 * Show that exp2 is actually exact for some easy values.
 */
rule exp2_correctValues() {
    assert(exp2(require_uint256(0 * ONE18())) == 1*ONE18());
    assert(exp2(require_uint256(1 * ONE18())) == 2*ONE18());
    assert(exp2(require_uint256(2 * ONE18())) == 4*ONE18());
    assert(exp2(require_uint256(3 * ONE18())) == 8*ONE18());
    assert(exp2(require_uint256(4 * ONE18())) == 16*ONE18());
}

rule exp2_additivity() {
    uint256 x; uint256 y; uint256 total;
    require total == x + y;
    require total <= 5*ONE18();

    assert exp2(total)*ONE18() == exp2(x) * exp2(y);
}

rule exp2_additivity2() {
    uint256 x; uint256 total;
    require total == x + x;
    require total <= 5*ONE18();

    assert exp2(total)*ONE18() == exp2(x) * exp2(x);
}

rule exp2_correctnes(uint8 n) {
    mathint BOUND = 100;
    uint256 x = require_uint256(n*ONE18());
    require n <= BOUND;
    
    assert exp2(x) == (1 << n) * ONE18();
}

rule exp2_monotone01(env e)
{
    mathint lBOUND = 0 * ONE18();
    mathint uBOUND = 1 * ONE18();
    uint256 x; uint256 y;
    require x >= lBOUND && y >= lBOUND;
    require x < uBOUND && y < uBOUND;
    
    assert x < y => exp2(x) <= exp2(y);
}

rule exp2_monotone12(env e)
{
    mathint lBOUND = 1 * ONE18();
    mathint uBOUND = 2 * ONE18();
    uint256 x; uint256 y;
    require x >= lBOUND && y >= lBOUND;
    require x < uBOUND && y < uBOUND;
    
    assert x < y => exp2(x) <= exp2(y);
}

/**
 * Prove that the inflation factor is bounded by MAX_INFLATION.
 */
invariant inflationFactorIsBounded()
    KatToken.inflationFactor() <= KatToken.MAX_INFLATION();

/**
 * Show that exp2 can not overflow within 100 years.
 * Technically, we show that exp2 stays below 0x100000000000000000, which is
 * well below anything close to an overflow.
 */
rule exp2_noOverflow() {
    // we know that the inflation factor is bounded by MAX_INFLATION
    uint256 inflationFactor = KatToken.inflationFactor();
    requireInvariant(inflationFactorIsBounded);
    // let's assume that we can't have more than 100 years of inflation
    uint256 timeElapsed;
    require(timeElapsed <= 100 * days(365));
    uint256 x = assert_uint256((inflationFactor * timeElapsed) / days(365));

    // that means x can't be more than 5
    assert(x < 5 * ONE18());

    // this is well below anything that might overflow ...
    assert(exp2(x) < 32 * ONE18() && 32 * ONE18() < 0x100000000000000000);
    // ... but the upper bound is reasonably tight
    satisfy(exp2(x) > 16 * ONE18());
}