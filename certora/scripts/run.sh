# run this from the root directory. i.e. via './certora/scripts/run.sh'
# certoraRun certora/confs/KatToken-simple.conf

certoraRun certora/confs/exp2-implementation.conf --rule exp2_monotone01 --rule exp2_monotone12
# certoraRun certora/confs/exp2-implementation.conf

# certoraRun certora/confs/MerkleMinter-simple.conf
