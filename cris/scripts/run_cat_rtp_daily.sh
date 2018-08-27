#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CAT_RTP_DAILY
# partition = dev/batch
#SBATCH --partition=prod
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=normal
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem=12000
#SBATCH --cpus-per-task 1
#SBATCH --time=02:00:00

#SBATCH --requeue

#SBATCH --mail-user=sbuczko1@umbc.edu
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=TIME_LIMIT_50

#SBATCH -o /home/sbuczko1/logs/sbatch/run_cat_rtp_daily-%A_%a.out
#SBATCH -e /home/sbuczko1/logs/sbatch/run_cat_rtp_daily-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing srun of run_cat_rtp_daily"
$MATLAB $MATOPT -r "addpath('/asl/packages/rtp_prod2/cris/scripts'); disp('>>Starting script');addpath('/asl/packages/swutils');cfg=ini2struct('$1'); run_cat_rtp_daily(cfg); exit"
    
echo "Finished with srun of run_cat_rtp_daily"



