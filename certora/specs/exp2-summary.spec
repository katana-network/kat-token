// Provides a summary for PowUtil.exp2 based on a ghost with some axioms.

methods {
    function PowUtil.exp2(uint256 x) internal returns (uint256) => cvlExp2(x);
}

definition ONE18() returns uint256 = 1000000000000000000;
definition TWO18() returns uint256 = 2000000000000000000;
ghost ghostExp2(uint256) returns uint256 {
    axiom ghostExp2(0) == ONE18();
    axiom ghostExp2(ONE18()) == TWO18();
    
    axiom forall uint256 y1. forall uint256 y2.
        y1 > y2 => ghostExp2(y1) >= ghostExp2(y2);
    axiom forall uint256 y.
        y > ONE18() => ghostExp2(y) >= TWO18();
    axiom forall uint256 y.
        y <= ONE18() => ghostExp2(y) <= TWO18();
}

function cvlExp2(uint256 x) returns uint256 {
    return ghostExp2(x);
}
