#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CREATE_AIRXBCAL_RTP
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=medium
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=18000
#SBATCH --time=01:20:00
#SBATCH -N1
#SBATCH --cpus-per-task=1

# matlab options
MATLAB=/usr/local/matlab/2015a/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

#LOGDIR=~/logs/sbatch
#DT=$(date +"%Y%m%d-%H%M%S")

echo "Executing run_airxbcal_batch"
$MATLAB $MATOPTS -r "addpath('~/git/rtp_prod2/airs/scripts'); run_airxbcal_batch; exit"
    
echo "Finished with run_airxbcal_batch"



