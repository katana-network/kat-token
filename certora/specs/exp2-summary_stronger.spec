// The same as exp2-summary.spec but it adds several additional axioms

methods {
    function PowUtil.exp2(uint256 x) internal returns (uint256) => cvlExp2(x);
}

definition ONE18() returns uint256 =  1000000000000000000;
definition Log2() returns uint256 =    693147180559945309;

ghost ghostExp2(mathint) returns uint256 {
    axiom ghostExp2(0) == ONE18();
    axiom ghostExp2(ONE18()) == 2*ONE18();

    axiom ghostExp2(2*ONE18()) == 4*ONE18();
    axiom ghostExp2(3*ONE18()) == 8*ONE18();
    axiom ghostExp2(4*ONE18()) == 16*ONE18();
    axiom ghostExp2(5*ONE18()) == 32*ONE18();
    axiom ghostExp2(6*ONE18()) == 64*ONE18();
    axiom ghostExp2(7*ONE18()) == 128*ONE18();
    axiom ghostExp2(8*ONE18()) == 256*ONE18();

    axiom forall uint256 x1. forall uint256 x2.
        x1 > x2 => ghostExp2(x1) >= ghostExp2(x2);
    axiom forall uint256 x.
        x >= ONE18() => ghostExp2(x) >= 2*ONE18();
    axiom forall uint256 x.
        x <= ONE18() => ghostExp2(x) <= 2*ONE18();

    // // lower bound
    // axiom forall uint256 x.
    //     ((x >= 0 && x < 2*ONE18()) => (
    //         ghostExp2(x) >=
    //             ONE18()
    //             + x * Log2() / ONE18()
    //             + x*x * Log2()*Log2() / ONE18()/ONE18()/ONE18() / 2
    //             + x*x*x * Log2()*Log2()*Log2() /ONE18()/ONE18()/ONE18()/ONE18()/ONE18() / 6
    //     )) &&
    //     ((x >= 2*ONE18() && x < 4*ONE18()) => (ghostExp2(x) >= ghostExp2(x - 2*ONE18()) * 4)) &&
    //     ((x >= 4*ONE18() && x < 6*ONE18()) => (ghostExp2(x) >= ghostExp2(x - 4*ONE18()) * 16)) &&
    //     ((x >= 6*ONE18() && x < 8*ONE18()) => (ghostExp2(x) >= ghostExp2(x - 6*ONE18()) * 64)) &&
    //     ((x >= 8*ONE18()) => (ghostExp2(x) >= ghostExp2(x - 8*ONE18()) * 256))
    // ;

    // upper bound
    axiom forall uint256 x.
        ((x >= 0 && x < 2*ONE18()) => (
            ghostExp2(x) <=
                4*ONE18()/3 // rough estimate: this approximation at 2 is about 0.21 to low
                + x * Log2() / ONE18()
                + x*x * Log2()*Log2() / ONE18()/ONE18()/ONE18() / 2
                + x*x*x * Log2()*Log2()*Log2() /ONE18()/ONE18()/ONE18()/ONE18()/ONE18() / 6
        )) &&
        ((x >= 2*ONE18() && x < 4*ONE18()) => (ghostExp2(x) <= ghostExp2(x - 2*ONE18()) * 4)) &&
        ((x >= 4*ONE18() && x < 6*ONE18()) => (ghostExp2(x) <= ghostExp2(x - 4*ONE18()) * 16)) &&
        ((x >= 6*ONE18() && x < 8*ONE18()) => (ghostExp2(x) <= ghostExp2(x - 6*ONE18()) * 64)) &&
        ((x >= 8*ONE18()) => (ghostExp2(x) <= ghostExp2(x - 8*ONE18()) * 256))
    ;
}

function cvlExp2(uint256 x) returns uint256 {
    return ghostExp2(x);
}
