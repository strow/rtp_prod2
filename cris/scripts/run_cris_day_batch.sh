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
#SBATCH --qos=medium
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem-per-cpu=18000
#SBATCH --cpus-per-task 1
#SBATCH --time=24:00:00

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'


#LOGDIR=~/logs/sbatch
#DT=$(date +"%Y%m%d-%H%M%S")

JOBSTEP=0

echo "Executing srun of run_cris_day_batch"
srun  $MATLAB $MATOPT -r "set_process_dirs; addpath(genpath(rtp_sw_dir)); run_cris_day_batch; exit"
    
echo "Finished with srun of run_cris_batch"



