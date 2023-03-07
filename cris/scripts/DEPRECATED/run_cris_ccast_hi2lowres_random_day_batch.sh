#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CRIS_HI2LR_RANDOM_DAY_BATCH
# partition = dev/batch
#SBATCH --partition=high_mem
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=medium+
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem=8000
#SBATCH --cpus-per-task 1
#SBATCH --time=05:59:00
#SBATCH --requeue

#SBATCH --mail-user=sbuczko1@umbc.edu
#SBATCH --mail-type=END
#SBATCH --mail-type=REQUEUE


#SBATCH -o /home/sbuczko1/LOGS/sbatch/run_cris_hi2lowres_random_day_batch-%A_%a.out
#SBATCH -e /home/sbuczko1/LOGS/sbatch/run_cris_hi2lowres_random_day_batch-%A_%a.err

# matlab options
MATLAB=matlab
MATOPT=' -nojvm -nodisplay -nosplash'

JOBSTEP=0

echo "Executing srun of run_cris_hi2lr_random_day_batch"
$MATLAB $MATOPT -r "disp('>>Starting script'); addpath('/asl/packages/swutils');cfg=ini2struct('$1');run_cris_ccast_hi2lowres_random_day_batch(cfg); exit"

echo "Finished with srun of run_cris_hi2lr_random_day_batch"



