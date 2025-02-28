// Provides a summary for PowUtil.exp2 based on a ghost with some axioms.

methods {
    function PowUtil.exp2(uint256 x) internal returns (uint256) => cvlExp2(x);
}

definition ONE18() returns uint256 =  1000000000000000000;
definition Log2() returns uint256 =    693147180559945309;

definition to18(uint256 x) returns mathint = x * ONE18();
definition taylor2xAt(uint256 min, uint256 max, uint256 mult) returns bool =
    forall uint256 x. (x >= min && x < max) => (
        ghostExp2(x) >= 
            to18(mult)
            + mult*(x-to18(min)) * Log2() / ONE18()
            + mult*(x-to18(min))*(x-to18(min)) * Log2()*Log2() / ONE18()/ONE18()/ONE18() / 2
            + mult*(x-to18(min))*(x-to18(min))*(x-to18(min)) * Log2()*Log2()*Log2() /ONE18()/ONE18()/ONE18()/ONE18()/ONE18() / 6
    );

ghost ghostExp2(mathint) returns uint256 {
    axiom ghostExp2(0) == ONE18();
    axiom ghostExp2(ONE18()) == 2*ONE18();

    axiom forall uint256 x1. forall uint256 x2.
        x1 > x2 => ghostExp2(x1) >= ghostExp2(x2);
    axiom forall uint256 x.
        x > ONE18() => ghostExp2(x) >= 2*ONE18();
    axiom forall uint256 x.
        x <= ONE18() => ghostExp2(x) <= 2*ONE18();

    axiom forall uint256 x.
        ((x >= 0 && x < 2*ONE18()) => (
            ghostExp2(x) >=
                ONE18()
                + x * Log2() / ONE18()
                + x*x * Log2()*Log2() / ONE18()/ONE18()/ONE18() / 2
                + x*x*x * Log2()*Log2()*Log2() /ONE18()/ONE18()/ONE18()/ONE18()/ONE18() / 6
        )) &&
        ((x >= 2*ONE18() && x < 4*ONE18()) => (ghostExp2(x) >= ghostExp2(x - 2*ONE18()) * 4)) &&
        ((x >= 4*ONE18() && x < 6*ONE18()) => (ghostExp2(x) >= ghostExp2(x - 4*ONE18()) * 16)) &&
        ((x >= 6*ONE18() && x < 8*ONE18()) => (ghostExp2(x) >= ghostExp2(x - 6*ONE18()) * 64)) &&
        ((x >= 8*ONE18()) => (ghostExp2(x) >= ghostExp2(x - 8*ONE18()) * 256))
    ;

}

function cvlExp2(uint256 x) returns uint256 {
    return ghostExp2(x);
}
