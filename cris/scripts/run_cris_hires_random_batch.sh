#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CREATE_CRIS_HR_RANDOM_RTP
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=short
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem-per-cpu=18000
#SBATCH --cpus-per-task 1
##SBATCH --array=0-179
#SBATCH --time=00:59:00

#SBATCH -o /home/sbuczko1/logs/sbatch/run_cris_hr_random_batch-%A_%a.out
#SBATCH -e /home/sbuczko1/logs/sbatch/run_cris_hr_random_batch-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing srun of run_cris_batch"
$MATLAB $MATOPT -r "disp('>>Starting script');addpath('/asl/packages/swutils');cfg=ini2struct('$1');run_cris_hires_random_batch(cfg); exit"
    
echo "Finished with run_cris_batch"



