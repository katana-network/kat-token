import "./exp2-summary.spec";

// Does some sanity checks on the exp2 summarization.

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

function lowerBound(mathint x, mathint res) {
    mathint e = exp2(assert_uint256(x));
    assert(10 * e >= 9*res);
}

rule exp2LowerBound() {
    lowerBound(0*ONE18(), ONE18());
    lowerBound(1*ONE18(), 2*ONE18());
    lowerBound(2*ONE18(), 4*ONE18());
    lowerBound(3*ONE18(), 8*ONE18());
    lowerBound(4*ONE18(), 16*ONE18());
    lowerBound(5*ONE18(), 32*ONE18());
    lowerBound(6*ONE18(), 64*ONE18());
    lowerBound(7*ONE18(), 128*ONE18());
    lowerBound(8*ONE18(), 256*ONE18());
    lowerBound(9*ONE18(), 512*ONE18());
    lowerBound(10*ONE18(), 1024*ONE18());

    lowerBound(1*ONE18()/2,  ONE18()*   14142 / 10000);
    lowerBound(3*ONE18()/2,  ONE18()*   28284 / 10000);
    lowerBound(5*ONE18()/2,  ONE18()*   56569 / 10000);
    lowerBound(7*ONE18()/2,  ONE18()*  113137 / 10000);
    lowerBound(9*ONE18()/2,  ONE18()*  226274 / 10000);
    lowerBound(11*ONE18()/2, ONE18()*  452548 / 10000);
    lowerBound(13*ONE18()/2, ONE18()*  905097 / 10000);
    lowerBound(15*ONE18()/2, ONE18()* 1810193 / 10000);
    lowerBound(17*ONE18()/2, ONE18()* 3620387 / 10000);
    lowerBound(19*ONE18()/2, ONE18()* 7240773 / 10000);
}

function upperBound(mathint x, mathint res) {
    mathint e = exp2(assert_uint256(x));
    assert(4 * e <= 5*res);
}

rule exp2UpperBound() {
    upperBound(0*ONE18(), ONE18());
    upperBound(1*ONE18(), 2*ONE18());
    upperBound(2*ONE18(), 4*ONE18());
    upperBound(3*ONE18(), 8*ONE18());
    upperBound(4*ONE18(), 16*ONE18());
    upperBound(5*ONE18(), 32*ONE18());
    upperBound(6*ONE18(), 64*ONE18());
    upperBound(7*ONE18(), 128*ONE18());
    upperBound(8*ONE18(), 256*ONE18());
    upperBound(9*ONE18(), 512*ONE18());
    upperBound(10*ONE18(), 1024*ONE18());

    upperBound(1*ONE18()/2,  ONE18()*   14142 / 10000);
    upperBound(3*ONE18()/2,  ONE18()*   28284 / 10000);
    upperBound(5*ONE18()/2,  ONE18()*   56569 / 10000);
    upperBound(7*ONE18()/2,  ONE18()*  113137 / 10000);
    upperBound(9*ONE18()/2,  ONE18()*  226274 / 10000);
    upperBound(11*ONE18()/2, ONE18()*  452548 / 10000);
    upperBound(13*ONE18()/2, ONE18()*  905097 / 10000);
    upperBound(15*ONE18()/2, ONE18()* 1810193 / 10000);
    upperBound(17*ONE18()/2, ONE18()* 3620387 / 10000);
    upperBound(19*ONE18()/2, ONE18()* 7240773 / 10000);
}
