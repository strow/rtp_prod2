function  run_cat_rtp_daily(cfg)
% CREATE_CAT_RTP_DAILY 
%
% read in a directory of rtp files (most likely constituting a day
% of data) and concatenate them into a single output rtp
% file. Calls cat_rtp_dir() which does the bulk of the actual
% concatenation. This routine drives input/output selection and
% does the final rtpwrite

addpath('/asl/packages/rtp_prod2/util');  % rtpread,rtpwrite,cat_rtp_dir

cris_daily_file_list = cfg.driver_file;

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

% for each slurm array index, process 30 days from the to-process
% list (because each day takes less time to process than it takes
% to load matlab so, it is inefficient to do each day as a
% separate array)
chunk = cfg.chunk;
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
    grabline = sprintf('sed -n "%dp" %s | tr -d "\n"', dayindex, ...
                       cris_daily_file_list);
    fprintf(1, '>>> Executing: %s\n', grabline);
    [status, indir] = system(grabline);
    if strcmp(indir, '')
        break;
    end

    % generate output file name and path (presently to be
    % /asl/data/rtp_cris_ccast_lowres/clear_daily/<year>/rtp_d<date>_clear.rtp)
    % /home/WorkingFiles/rtp_cris_ccast_lowres/random/YYYY/DOY/cris_lr_era_d20150831_t2323522_random.rtp
    C = strsplit(indir, '/');
    sYear = C{6};  % changed to fit local diectory structure
    sDoy = C{7};
    outpath = fullfile(cfg.outpath, cfg.type, sYear);

    % read in filenames in indir to build output filename
    mfiles = dir(fullfile(indir, sprintf('%s_*.rtp', cfg.filebase)));

    [path, name, ext] = fileparts(mfiles(1).name);
    C = strsplit(name, '_');
    outfile = fullfile(outpath, sprintf('%s_%s.rtp', cfg.filebase, C{5}));


    fprintf(1, '>>> Output to: %s\n', outfile);

    % check to see if the output file is extant on the system
    % (don't overwrite for now.)
% $$$     if exist(outfile, 'file') == 0
        % concatenate rtp files in indir
        [h,ha,p,pa] = cat_rtp_dir(indir);

        % write out concatenated rtp file
        lmax = 65000;    % to keep output file below HDF4 limit
        if length(p.rtime) > lmax
            rand_ind = randperm(length(p.rtime), lmax);
            p = rtp_sub_prof(p, rand_ind);
        end  % end if length
            
        try
            rtpwrite(outfile, h,ha,p,pa);
        catch
            fprintf(2, '>>> rtpwrite failure in chunk %d for %s\n', i, indir);
        end  % end try-catch
        fprintf(1, '>>> Successfully wrote %s\n', outfile);
                        
% $$$     else
% $$$         fprintf(1, '>>> %s exists. Skipping\n', outfile);
% $$$     end  % end if exist()
    
end  % ends loop over chunk
%% ****end function run_cat_rtp_daily****
