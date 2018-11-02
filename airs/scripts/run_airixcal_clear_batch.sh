#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CREATE_AIRIXCAL_CLEAR_RTP
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=short
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=18000
#SBATCH --time=00:59:00
#SBATCH -N1
#SBATCH --cpus-per-task=1
#SBATCH --requeue

#SBATCH --mail-user=sbuczko1@umbc.edu
##SBATCH --mail-type=BEGIN
##SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=TIME_LIMIT_50

#SBATCH -o /home/sbuczko1/logs/sbatch/run_airixcal_clear_batch-%A_%a.out
#SBATCH -e /home/sbuczko1/logs/sbatch/run_airixcal_clear_batch-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing run_airixcal_clear_batch"
$MATLAB $MATOPTS -r "addpath(genpath('~/git/rtp_prod2_PROD'), '~/git/swutils'); run_airixcal_clear_batch; exit"
    
echo "Finished with run_airixcal_clear_batch"



