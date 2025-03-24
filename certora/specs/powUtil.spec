/**
 * Check properties on the actual implementation here.
 */

using KatToken as KatToken;

methods {
    function exp2(uint256 x) external returns (uint256) envfree;

    function KatToken.inflationFactor() external returns (uint256) envfree;
    function KatToken.MAX_INFLATION() external returns (uint256) envfree;
    function _.eip712Domain() external => NONDET DELETE;
}

definition ONE18() returns uint256 =  1000000000000000000;
definition daysToSeconds(uint256 days) returns uint256 = assert_uint256(days * 60 * 60 * 24);

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

rule exp2_monotonePlus01(env e)
{
    mathint lBOUND = 0 * ONE18();
    mathint uBOUND = 1 * 10^10;
    uint256 x;
    require x >= lBOUND;
    require x < uBOUND;
    
    assert exp2(x) <= exp2(require_uint256(x+1));
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

rule exp2_monotonicityX(env e)
{
    uint256 MIN_INFLATION =  1441974173906322; // log2(1.001)
    uint256 MAX_INFLATION = 42644337408493690; // log2(1.03)
    uint secondsPerYear = (365 *24 *60 *60);
    uint256 minDifference = require_uint256(MIN_INFLATION / secondsPerYear);

    uint256 inflFactor; uint256 timeElapsed;
    require inflFactor >= MIN_INFLATION && inflFactor <= MAX_INFLATION;
    require timeElapsed <= 7 *24 *60 *60;   //one week

    uint256 input = require_uint256(inflFactor * timeElapsed / secondsPerYear);
    assert exp2(input) <= exp2(require_uint256(input + minDifference));
}

function withinTenPercentTolerance(mathint a, mathint b) returns bool
{
    return 9*a <= 10*b && 9*b <= 10*a;
}

rule exp2_additivity2X() {
    uint256 x; uint256 total;
    require total == x + x;
    require total <= 5*ONE18();

    assert withinTenPercentTolerance(exp2(total)*ONE18(), exp2(x) * exp2(x));
}
