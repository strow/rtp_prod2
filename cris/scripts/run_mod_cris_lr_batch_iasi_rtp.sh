#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_MOD_CRIS_LR_BATCH_IASI
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=normal
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem-per-cpu=18000
#SBATCH --cpus-per-task 1
#SBATCH --time=02:30:00
#SBATCH --requeue

#SBATCH --mail-user=sbuczko1@umbc.edu
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=TIME_LIMIT_50

#SBATCH -o /home/sbuczko1/logs/sbatch/run_mod_cris_lr_batch-%A_%a.out
#SBATCH -e /home/sbuczko1/logs/sbatch/run_mod_cris_lr_batch-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

JOBSTEP=0

echo "Executing srun of run_cris_lr_batch"
$MATLAB $MATOPT -r "set_process_dirs; addpath(genpath(rtp_sw_dir)); run_mod_cris_lr_batch_iasi_rtp; exit"

echo "Finished with srun of run_mod_cris_lr_batch_iasi_rtp"



