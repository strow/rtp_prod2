#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CREATE_CRIS_HR_RANDOM_DAY_RTP
# partition = dev/batch
#SBATCH --partition=high_mem
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=normal+
#SBATCH --account=pi_strow
#SBATCH -N1
#SBATCH --mem-per-cpu=20000
#SBATCH --cpus-per-task 1
##SBATCH --array=0-179
#SBATCH --time=03:59:00

#SBATCH -o /home/sbuczko1/LOGS/sbatch/run_cris_hr_random_day_batch-%A_%a.out
#SBATCH -e /home/sbuczko1/LOGS/sbatch/run_cris_hr_random_day_batch-%A_%a.err

# matlab options
MATLAB=matlab
MATOPT=' -nojvm -nodisplay -nosplash'

echo "Executing srun of run_cris_batch"
$MATLAB $MATOPT -r "disp('>>Starting script');run_cris_hires_random_day_batch('$1'); exit"
    
echo "Finished with run_cris_batch"



