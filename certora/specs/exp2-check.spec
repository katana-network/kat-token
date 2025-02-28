import "./exp2-summary.spec";

methods {
    function exp2(uint256 x) external returns (uint256) envfree;
}

function maybeEqual(mathint x, mathint res) {
    uint256 e = exp2(assert_uint256(x));
    satisfy(99 * e < 100 * res && 101 * e > 100 * res);
}

rule exp2Consts() {
    maybeEqual(0*ONE18(), ONE18());
    maybeEqual(1*ONE18(), 2*ONE18());
    maybeEqual(2*ONE18(), 4*ONE18());
    maybeEqual(3*ONE18(), 8*ONE18());
    maybeEqual(4*ONE18(), 16*ONE18());
    maybeEqual(5*ONE18(), 32*ONE18());
    maybeEqual(6*ONE18(), 64*ONE18());
}

rule exp2Monotonicity() {
    uint256 x;
    uint256 y;
    // weak monotonicity
    assert((x < y) => (exp2(x) <= exp2(y)));
}
