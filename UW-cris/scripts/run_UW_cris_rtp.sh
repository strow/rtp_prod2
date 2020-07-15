#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_UW_CRIS_RTP
# partition = dev/batch
#SBATCH --partition=high_mem
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=medium+
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=18000
#SBATCH --time=07:59:00
#SBATCH -N1
#SBATCH --cpus-per-task=1
#SBATCH --requeue

#SBATCH -o /home/sbuczko1/LOGS/sbatch/run_uwcris_batch-%A_%a.out
#SBATCH -e /home/sbuczko1/LOGS/sbatch/run_uwcris_batch-%A_%a.err

# matlab options
MATLAB=matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing run_uwcris_batch"
$MATLAB $MATOPT -r "disp('>>Starting script');\
                    cris_nc_addpaths;\
                    cfg=ini2struct('$1');\
                    run_UW_cris_rtp(cfg);\
                    exit"
    
echo "Finished with run_uwcris_batch"



