#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CREATE_CRIS_RTP
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=short
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=sbuczko1@umbc.edu
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem-per-cpu=18000
#SBATCH --cpus-per-task 1
#SBATCH --array=1-540
#SBATCH --time=00:40:00

# matlab options
MATLAB=/usr/cluster/matlab/2014b/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'


LOGDIR=~/logs/sbatch
DT=$(date +"%Y%m%d-%H%M%S")

JOBSTEP=0
RTP_PROD2=~/git/rtp_prod2

echo "Executing srun of run_cris_batch"
srun --output=${LOGDIR}/run_cris_rtp_$((++JOBSTEP))_%j_%t-${DT}.out \
    $MATLAB $MATOPTS -r "addpath(genpath('$RTP_PROD2')); run_cris_batch; exit"
    
echo "Finished with srun of run_cris_batch"



