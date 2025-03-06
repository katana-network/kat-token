import "./exp2-summary.spec";

methods {
    function inflationAdmin() external returns (address) envfree;
    function inflationBeneficiary() external returns (address) envfree;
    function inflationFactor() external returns (uint256) envfree;
    function MAX_INFLATION() external returns (uint256) envfree;
    function merkleMinter() external returns (address) envfree;
    function mintCapacity(address) external returns (uint256) envfree;
}

rule nonTrivialDistributeInflation() {
    env e;

    // enforce non-trivial inflation
    require(inflationFactor() > MAX_INFLATION() / 2);
    require(inflationFactor() < MAX_INFLATION());

    uint256 capacityBefore = mintCapacity(inflationBeneficiary());

    distributeInflation(e);

    uint256 capacityAfter = mintCapacity(inflationBeneficiary());
    satisfy(capacityAfter > capacityBefore);
}