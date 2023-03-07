#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CLIMCAPS_RTP
# partition = dev/batch
#SBATCH --partition=high_mem
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=short+
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=18000
#SBATCH --time=00:39:00
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
                    cris_nc_addpaths;\
                    cfg=ini2struct('$1');\
                    run_climcaps_rtp(cfg);\
                    exit"
    
echo "Finished with run_climcaps_batch"



