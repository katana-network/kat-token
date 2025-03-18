# certoraRun certora/confs/KatToken.conf

# certoraRun certora/confs/powUtil.conf --rule exp2_monotonePlus01
# certoraRun certora/confs/powUtil.conf


# the rule indexIsClaimedValueChange requires using bitVector theory
certoraRun certora/confs/MerkleMinter.conf --rule indexIsClaimedValueChange --prover_args -smt_bitVectorTheory true --msg "MerkleMinter indexIsClaimedValueChange" 
# all the other rules can be verified using the default integer theory
# certoraRun certora/confs/MerkleMinter.conf --exclude_rule indexIsClaimedValueChange
