import "./exp2-summary.spec";

methods {
    function exp2(uint256 x) external returns (uint256) envfree;
}

function almost_equal(mathint x, mathint res) {
    uint256 e = exp2(assert_uint256(x));
    satisfy(99 * e < 100 * res && 101 * e > 100 * res);
}

rule exp2GhostMakesSense() {
    almost_equal(0*ONE18(), ONE18());
    almost_equal(1*ONE18(), 2*ONE18());
    almost_equal(2*ONE18(), 4*ONE18());
    almost_equal(3*ONE18(), 8*ONE18());
    almost_equal(4*ONE18(), 16*ONE18());
    almost_equal(5*ONE18(), 32*ONE18());
    almost_equal(6*ONE18(), 64*ONE18());
}
