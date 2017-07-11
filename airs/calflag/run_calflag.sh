#!/bin/bash
#
# usage: 
#
# 

# sbatch options
#SBATCH --job-name=RUN_CALFLAG
# #SBATCH --nodes=20
#SBATCH --ntasks=2
# #SBATCH --ntasks-per-node=2
# partition = dev/batch
#SBATCH --partition=batch
# qos = short/normal/medium/long/long_contrib
#SBATCH --qos=medium
#SBATCH --account=pi_strow
# #SBATCH --constraint=hpcf2013
# #SBATCH --exclusive
#SBATCH --mem-per-cpu=18000

# start doy and year
STARTDOY=$1
STARTYEAR=$2

# ending doy and year
ENDDOY=$3
ENDYEAR=$4

JOBNAME=create_calflag

# get task_id
TASKID=$SLURM_JOB_ID

# matlab options
MATLAB=/usr/cluster/matlab/2014b/bin/matlab
MATOPT=' -nojvm -nodisplay -nosplash'


LOGDIR=~/logs/sbatch
DT=$(date +"%Y%m%d-%H%M%S")

# run fill_job_table_range to create processing stack
$MATLAB $MATOPTS -r "addpath(genpath('/home/sbuczko1/git/rtp_prod2/')); addpath(genpath('~/git/slurmutil/matlab')); which fill_job_table_range; fill_job_table_range($STARTYEAR, $STARTDOY, $ENDYEAR, $ENDDOY, $TASKID, '$JOBNAME'); exit"

JOBSTEP=0

echo "Executing srun of run_airibrad_batch"
srun --output=${LOGDIR}/run_create_calflag_$((++JOBSTEP))_%j_%t-${DT}.out \
    $MATLAB $MATOPTS -r "addpath('~/prgdir/src/matlab'); addpath(genpath('/home/sbuczko1/git/rtp_prod2/')); addpath(genpath('~/git/slurmutil/matlab')); which run_AIRIBRAD_batch; run_AIRIBRAD_batch($TASKID); exit"
    
echo "Finished with srun of run_airibrad_batch"



