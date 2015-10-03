#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_AIRIBRAD_RAND
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=medium
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem-per-cpu=18000
#SBATCH --cpus-per-task=1
#SBATCH --time=14:00:00
###SBATCH --array=0-156

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing run_airibrad_rand"
$MATLAB $MATOPT -r "addpath('~/git/rtp_prod2/airs/scripts'); run_airibrad_rand; exit"
    
echo "Finished with run_airibrad_rand"



