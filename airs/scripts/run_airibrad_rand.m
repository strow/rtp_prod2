function  run_airibrad_rand()
% 
%
% read in a directory of rtp files (most likely constituting a day
% of data) and concatenate them into a single output rtp
% file. Calls cat_rtp_dir() which does the bulk of the actual
% concatenation. This routine drives input/output selection and
% does the final rtpwrite

addpath('~/git/rtp_prod2/util');  % rtpread,rtpwrite,cat_rtp_dir
addpath('~/git/rtp_prod2/airs');  % sub_airxbcal

% 
airs_daily_file_list = '~/airibrad_days_to_process.txt';

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));
%slurmindex = 0;

% for each slurm array index, process 30 days from the to-process
% list (because each day takes less time to process than it takes
% to load matlab so, it is inefficient to do each day as a
% separate array)
chunk = 1;
for i = 1:chunk
    dayindex = (slurmindex*chunk) + i;
    %    dayindex=281; % testing testing testing
    fprintf(1, '>>> chunk %d    dayindex %d\n', i, dayindex);
    
    % File ~/cris-files-process.txt is a list of filepaths to the input
    % files or this processing. For the initial runs, this was
    % generated by a call to 'ls' while sitting in the directory
    % /asl/data/cris/ccast/sdr60_hr/2015: 
    %    ls -d1 $PWD/{048,049,050}/*.mat >> ~/cris-files-process.txt
    %
    % cris-files-process.txt, then, contains lines like:
    %    /asl/data/cris/ccast/sdr60_hr/2015/048/SDR_d20150217_t1126169.mat
    [status, inpath] = system(sprintf('sed -n "%dp" %s | tr -d "\n"', ...
                                     dayindex, airs_daily_file_list));
    if strcmp(inpath, '')
        break;
    end

    %cfg.model = 'era';
    cfg.model = 'nomodel';
    outfile_head = '/asl/rtp/rtp_airibrad_v5';
% $$$     outfile_head = '/home/sbuczko1/WorkingFiles/rtp_airibrad_v5';
    create_airibrad_random_nadir_rtp(inpath, outfile_head, cfg);
    
end  % ends loop over chunk
%% ****end function run_cat_rtp_daily****
