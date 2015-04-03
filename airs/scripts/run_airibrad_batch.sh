#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CREATE_AIRXBCAL_RTP
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=normal
#SBATCH -N1
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=5000
#SBATCH --cpus-per-task=4
#SBATCH --array=1-3
#SBATCH --time=00:60:00

# job table matlab functions
JTDIR=~/git/slurmutil/matlab

# start doy and year
STARTDOY=$1
STARTYEAR=$2

# ending doy and year
ENDDOY=$3
ENDYEAR=$4

JOBNAME=create_airxbcal_rtp

# get task_id
TASKID=$SLURM_JOB_ID

# matlab options
MATLAB=/usr/cluster/matlab/2014b/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'


LOGDIR=~/logs/sbatch
DT=$(date +"%Y%m%d-%H%M%S")

# run fill_job_table_range to create processing stack
RTP_PROD2=/home/sbuczko1/git/rtp_prod2/airs
JTUTILS=/home/sbuczko1/git/slurmutil/matlab
$MATLAB $MATOPTS -r "addpath(genpath('$RTP_PROD2'), genpath('$JTUTILS')); fill_job_table_range($STARTYEAR, $STARTDOY, $ENDYEAR, $ENDDOY, $TASKID, '$JOBNAME'); exit"

JOBSTEP=0

echo "Executing srun of run_airxbcal_batch"
srun --output=${LOGDIR}/run_create_airxbcal_rtp_$((++JOBSTEP))_%j_%t-${DT}.out \
    $MATLAB $MATOPTS -r "addpath(genpath('$RTP_PROD2'), genpath('$JTUTILS')); run_airxbcal_batch($TASKID); exit"
    
echo "Finished with srun of run_airxbcal_batch"



