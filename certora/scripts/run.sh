certoraRun certora/confs/KatToken.conf
certoraRun certora/confs/KatToken.conf --verify KatTokenHarness:certora/specs/KatToken_changeInflation.spec --msg changeInflation_revertConditions

# the rule indexIsClaimedValueChange requires using bitVector theory
certoraRun certora/confs/MerkleMinter.conf --rule indexIsClaimedValueChange --prover_args -smt_bitVectorTheory true --msg "MerkleMinter indexIsClaimedValueChange" 
# all the other rules can be verified using the default integer theory
certoraRun certora/confs/MerkleMinter.conf --exclude_rule indexIsClaimedValueChange