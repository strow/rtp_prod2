#!/bin/bash

# makes sbatch calls to run run_pull_stats for all extant filter combinations
#
# currently this makes sense for random subset only

for i={1..6}; do
    sbatch run_pull_stats.sh $1
done




    
    
