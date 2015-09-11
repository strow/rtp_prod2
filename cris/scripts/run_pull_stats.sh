#!/bin/bash
#
# usage: sbatch run_pull_stats filter
#
# where filter = {1..6}
# 1 = descending (night), land & ocean
# 2 = desc, ocean
# 3 = desc, land
# 4 = ascending (day, land & ocean
# 5 = asc, ocean
# 6 = asc, land

# sbatch options
#SBATCH --job-name=RUN_LR_PULL_STATS
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=medium
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem-per-cpu=18000
#SBATCH --cpus-per-task 1
#SBATCH --time=06:00:00
# low res has data from 2012 to present: 4 years
#SBATCH --array=0-3

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'


LOGDIR=~/logs/sbatch
DT=$(date +"%Y%m%d-%H%M%S")

JOBSTEP=0

echo "Executing srun of run_pull_stats"
srun  $MATLAB $MATOPT -r "addpath(genpath('~/git/rtp_prod2')); run_pull_stats($1); exit"
    
echo "Finished with srun of run_pull_stats"



