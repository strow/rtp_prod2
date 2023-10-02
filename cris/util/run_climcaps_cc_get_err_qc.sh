#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CLIMCAPS_ERR_QC
# partition = dev/batch
#SBATCH --partition=high_mem
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=normal+
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=18000
#SBATCH --time=01:39:00
#SBATCH -N1
#SBATCH --cpus-per-task=1
#SBATCH --requeue

#SBATCH -o /home/sbuczko1/LOGS/sbatch/run_climcaps_batch-%A_%a.out
#SBATCH -e /home/sbuczko1/LOGS/sbatch/run_climcaps_batch-%A_%a.err

# matlab options
MATLAB=matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing run_climcaps_batch"
$MATLAB $MATOPT -r "disp('>>Starting script');\
                    addpath('/home/sbuczko1/git/rtp_prod2_DEV/cris/misc');\
                    run_climcaps_cc_get_err_qc('$1');\
                    exit"
    
echo "Finished with run_climcaps_batch"



