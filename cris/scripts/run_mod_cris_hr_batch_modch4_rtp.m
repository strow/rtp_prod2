function run_mod_cris_hr_batch_modch4_rtp()
set_process_dirs;
addpath(genpath(rtp_sw_dir));
addpath('/home/sbuczko1/git/rtp_prod2/util');

cris_ccast_mod_file_list = '~/cris_hr_mod_ch4';

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));   % 0-19999

% collect some system parameters to log
[~, hostname] = system('hostname');
slurm_job_id = getenv('SLURM_JOB_ID');
slurm_array_job_id = getenv('SLURM_ARRAY_JOB_ID')
fprintf(1, '*** Hostname: %s\tJobID: %s\tArray JobID: %s\n', hostname, ...
        slurm_job_id, slurm_array_job_id);
slurm_job_partition = getenv('SLURM_JOB_PARTITION');
slurm_restart_count = getenv('SLURM_RESTART_COUNT');
fprintf(1, '*** Partition: %s\tRestart Count: %s\n', slurm_job_partition, ...
        slurm_restart_count);
slurm_submit_host = getenv('SLURM_SUBMIT_HOST');
slurm_submit_dir = getenv('SLURM_SUBMIT_DIR');
fprintf(1, '*** Submit host: %s\tSubmit dir: %s\n', slurm_submit_host, ...
        slurm_submit_dir);
[sID, sTempPath] = genscratchpath();
fprintf(1, '*** Temp path: %s\tTemp sID: %s\n', sTempPath, sID);
fprintf(1, '*** Task run start %s\n', char(datetime('now')));

% run data in chunks to get around MaxArraySize
% boundary AND better utilize the cluster
chunk = 1;
for i = 1:chunk
    fileindex = (slurmindex*chunk) + i;
    % File ~/cris-files-process.txt is a list of filepaths to the input
    % files or this processing. For the initial runs, this was
    % generated by a call to 'ls' while sitting in the directory
    % /asl/data/cris/ccast/sdr60_hr/2015: 
    %    ls -d1 $PWD/{048,049,050}/*.mat >> ~/cris-files-process.txt
    %
    % cris-files-process.txt, then, contains lines like:
    %    /asl/data/cris/ccast/sdr60_hr/2015/048/SDR_d20150217_t1126169.mat
    [status, infile] = system(sprintf('sed -n "%dp" %s | tr -d "\n"', ...
                                      fileindex, cris_ccast_mod_file_list));

    % call the processing function
    fprintf(1, '> Processing cris rtp file %s\n', infile);

        modify_cris_ccast_ch4_rtp(infile);
% $$$     catch
% $$$         fprintf(2, '>>> ERROR :: Processing failed for cris rtp file %s\n', ...
% $$$                 infile);
% $$$     end

end  % end chunk loop