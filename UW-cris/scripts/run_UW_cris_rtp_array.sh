#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_UW_CRIS_RTP
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=short
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=18000
#SBATCH --time=01:00:00
#SBATCH -N1
#SBATCH --cpus-per-task=1
#SBATCH --requeue

#SBATCH --mail-user=sbuczko1@umbc.edu
##SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=TIME_LIMIT_50

#SBATCH -o /home/sbuczko1/logs/sbatch/run_uwcris_batch-%A_%a.out
#SBATCH -e /home/sbuczko1/logs/sbatch/run_uwcris_batch-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing run_uwcris_batch"
$MATLAB $MATOPTS -r "addpath(genpath('~/git/rtp_prod2')); run_UW_cris_rtp_array; exit"
    
echo "Finished with run_uwcris_batch"



