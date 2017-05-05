#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_AIRICRAD_ALLFOV
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=short
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --cpus-per-task=1
#SBATCH --requeue

# Previous runs (2313403) put MaxRSS below 7GB
#SBATCH --mem=18000

# Previous runs put run time at ~6 minutes for a granule
#SBATCH --time=00:30:00

#SBATCH --mail-user=sbuczko1@umbc.edu
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=TIME_LIMIT_50

#SBATCH -o /home/sbuczko1/logs/sbatch/run_airicrad_allfov_rtp-%A_%a.out
#SBATCH -e /home/sbuczko1/logs/sbatch/run_airicrad_allfov_rtp-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing run_airicrad_rand"
$MATLAB $MATOPT -r "addpath('~/git/swutils', '~/git/rtp_prod2/airs/scripts'); run_airicrad_allfov_gran; exit"
    
echo "Finished with run_airicrad_rand"



