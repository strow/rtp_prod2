function run_pull_stats(filter)
set_process_dirs;
addpath(genpath(rtp_sw_dir));

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

year = 2012+slurmindex;
disp(year)
pull_stats_cris(year,filter);
