#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_IASI_FIX_FILL_ERA
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=medium
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=18000
#SBATCH --time=12:00:00
#SBATCH -N1
#SBATCH --cpus-per-task=1
#SBATCH --requeue

#SBATCH --mail-user=sbuczko1@umbc.edu
##SBATCH --mail-type=BEGIN
##SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=TIME_LIMIT_50

#SBATCH -o /home/sbuczko1/logs/sbatch/run_iasi_fix_fill_era-%A_%a.out
#SBATCH -e /home/sbuczko1/logs/sbatch/run_iasi_fix_fill_era-%A_%a.err

# matlab options
MATLAB=/usr/cluster/matlab/current/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing run_iasi_fix_fill_era"
$MATLAB $MATOPTS -r "addpath('/asl/packages/rtp_prod2/iasi'); run_iasi_fix_fill_era; exit"
    
echo "Finished with run_iasi_fix_fill_era"



