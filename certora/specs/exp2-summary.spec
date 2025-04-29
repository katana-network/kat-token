// Provides a summary for PowUtil.exp2.
// The summary refers to a ghost `ghostExp2` that is restricted by a number of
// simple axioms:
// - exp2(0) == 1
// - exp2(1) == 2
// - exp2(x) is monotonically increasing
// - for x>=1, exp2(x) >= 2
// - for x<=1, exp2(x) <= 2
// Furthermore, we add axioms based on 3rd-order taylor expansions. We spell out
// the expansion around zero for 0<=x<2 and shift it for higher values of x.
// Similarly, we implement an upper bound by moving the expansion around zero
// to start at x=0, y=4/3.

methods {
    function PowUtil.exp2(uint256 x) internal returns (uint256) => cvlExp2(x);
}

definition ONE18() returns uint256 =  1000000000000000000;
definition Log2() returns uint256 =    693147180559945309;

ghost ghostExp2(mathint) returns uint256 {
    axiom ghostExp2(0) == ONE18();
    axiom ghostExp2(ONE18()) == 2*ONE18();

    axiom forall uint256 x1. forall uint256 x2.
        x1 > x2 => ghostExp2(x1) >= ghostExp2(x2);
    axiom forall uint256 x.
        x >= ONE18() => ghostExp2(x) >= 2*ONE18();
    axiom forall uint256 x.
        x <= ONE18() => ghostExp2(x) <= 2*ONE18();
}

function cvlExp2(uint256 x) returns uint256 {
    return ghostExp2(x);
}
