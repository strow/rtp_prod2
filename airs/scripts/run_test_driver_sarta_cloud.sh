#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_TEST_DRIVER_SARTA_CLOUD
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=short
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --cpus-per-task=1

# Previous runs (2313403) put MaxRSS below 7GB
#SBATCH --mem=12000

# Previous runs (2313403) put run time at ~2 hours for a 4 day chunk (.5 hour/day) 
#SBATCH --time=00:59:00

#SBATCH --array=0-15

#SBATCH --mail-user=sbuczko1@umbc.edu
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=TIME_LIMIT_50

#SBATCH -o /home/sbuczko1/logs/sbatch/run_test_driver_sarta_cloud_rtp-%A_%a.out
#SBATCH -e /home/sbuczko1/logs/sbatch/run_test_driver_sarta_cloud_rtp-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing run_test_driver_sarta_cloud"
$MATLAB $MATOPT -r "addpath('~/git/swutils', '~/git/rtp_prod2_PROD/airs/scripts'); run_test_driver_sarta_cloud; exit"
    
echo "Finished with run_test_driver_sarta_cloud"



