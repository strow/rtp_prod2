#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CRIS_LR_DAY_BATCH
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=medium
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem=8000
#SBATCH --cpus-per-task 1
#SBATCH --time=14:00:00
#SBATCH --requeue

#SBATCH --mail-user=sbuczko1@umbc.edu
#SBATCH --mail-type=END
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=TIME_LIMIT_50

#SBATCH -o /home/sbuczko1/logs/sbatch/run_cris_lr_day_batch-%A_%a.out
#SBATCH -e /home/sbuczko1/logs/sbatch/run_cris_lr_day_batch-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

JOBSTEP=0

echo "Executing srun of run_cris_lr_day_batch"
$MATLAB $MATOPT -r "set_process_dirs; addpath(genpath(rtp_sw_dir)); run_cris_lr_day_batch; exit"

echo "Finished with srun of run_cris_lr_day_batch"



