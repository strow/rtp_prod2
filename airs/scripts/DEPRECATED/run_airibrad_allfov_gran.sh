#!/bin/bash
#
# usage: 
#
# 

# sbatch default options (can override with CL switches)
#SBATCH --job-name=RUN_AIRIBRAD_ALLFOV
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=normal+
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --cpus-per-task=1
#SBATCH --requeue

# Previous runs (2313403) put MaxRSS below 7GB
#SBATCH --mem=12000

# Previous runs put run time at ~6 minutes for a granule
#SBATCH --time=03:59:00

#SBATCH --mail-user=sbuczko1@umbc.edu
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=TIME_LIMIT_50

#SBATCH -o /home/sbuczko1/LOGS/sbatch/run_airibrad_allfov_rtp-%A_%a.out
#SBATCH -e /home/sbuczko1/LOGS/sbatch/run_airibrad_allfov_rtp-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing run_airibrad_rand"
$MATLAB $MATOPT -r "airs_rtpaddpaths;\
                    run_airibrad_allfov_gran($1);\
                    exit"
    
echo "Finished with run_airibrad_rand"



