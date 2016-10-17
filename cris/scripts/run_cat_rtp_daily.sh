#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CAT_RTP_DAILY
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=normal
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem=12000
#SBATCH --cpus-per-task 1
#SBATCH --time=03:00:00

#SBATCH --requeue

#SBATCH --mail-user=sbuczko1@umbc.edu
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=TIME_LIMIT_50

#SBATCH -o /home/sbuczko1/logs/sbatch/run_cat_rtp_daily-%A_%a.out
#SBATCH -e /home/sbuczko1/logs/sbatch/run_cat_rtp_daily-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing srun of run_cat_rtp_daily"
$MATLAB $MATOPT -r "addpath('~/git/rtp_prod2/cris/scripts'); run_cat_rtp_daily(); exit"
    
echo "Finished with srun of run_cat_rtp_daily"



