#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_AIRICRAD_ALLFOV
# partition = dev/batch
#SBATCH --partition=high_mem
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=short+
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --cpus-per-task=1
#SBATCH --requeue

# Previous runs (2313403) put MaxRSS below 7GB
#SBATCH --mem=18000

# Previous runs put run time at ~6 minutes for a granule
#SBATCH --time=00:50:00

#SBATCH --mail-user=sbuczko1@umbc.edu
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE

#SBATCH -o /home/sbuczko1/LOGS/sbatch/run_airicrad_allfov_rtp-%A_%a.out
#SBATCH -e /home/sbuczko1/LOGS/sbatch/run_airicrad_allfov_rtp-%A_%a.err

# matlab options
MATLAB=matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing run_airicrad_allfov"
$MATLAB $MATOPT -r "disp('>>Starting script');\
                    airs_rtpaddpaths;\
                    cfg=ini2struct('$1');\
                    run_airicrad_allfov_gran(cfg);\
                    exit"
    
echo "Finished with run_airicrad_allfov"



