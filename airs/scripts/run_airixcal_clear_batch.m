function run_airixcal_clear_batch()

addpath('/home/sbuczko1/git/rtp_prod2_PROD/airs/');
% 
airs_daily_file_list = '/home/sbuczko1/rtp_gen_files/airixcal-days-to-process';
airixcal_out_dir = '/asl/rtp/rtp_airixcal_v11';

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));
if ~exist('slurmindex')
    slurmindex = 0;
end

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

    % YEAR and DOY are in the retrieved filename. Parse this and
    % pull them out
    [fpath, fname, fext] = fileparts(inpath)
    C = strsplit(fname,'.');
    tstamp = C{4};
    dt = datetime(tstamp, 'InputFormat', 'yyyyMMdd');
    iYear = year(dt);
    iMonth = month(dt);
    iDay = day(dt, 'dayofmonth');
    iDoy = day(dt, 'dayofyear');
  
    fprintf(1, 'run_airixcal_batch: processing day %03d, year %4d\n', ...
            iDoy, iYear)

    cfg.model='era';
    [head,hattr,prof,pattr] = create_airixcal_clear_rtp(inpath, cfg);

    % Subset into four types and save separately
    % 1 - clear; 2 - site; 3 - dcc; 4 - random nadir; 5 - hottest
    % in gran; 6 - AMSU-B dcc; 7 - low strat
    iclear = find(bitget(prof.iudef(1,:),1));

    asType = {'clear' 'iclear'};
    if length(iclear) < 0
        fprintf(2, '>> AIRS year %4d  day %03d has no %s obs\n', iYear, ...
                iDoy, asType{1,1});
        break
    end  % if length()

    % Make directory if needed
    sPath = fullfile(airixcal_out_dir, num2str(iYear), asType{1,1});
    if exist(sPath) == 0
        mkdir(sPath);
    end  % if exist()

    rtp_out_fn_head = sprintf('era_airixcal_day%03d', iDoy);

    fprintf(1, '>>> writing output rtp files... ');

    prof_subset = rtp_sub_prof(prof,iclear);

    % if nobs is greater than threshold lmax, subset to
    % avoid rtp file size limitations (2GB) 
    lmax = 20000;
    nobs = length(prof_subset.rtime);
    fprintf(1, '>>> *** %d pre-subset obs ***\n', nobs);
    if nobs > lmax
        fprintf(1, '>>>*** nobs > %d. subsetting clear... ', lmax);
        saveinds = randperm(nobs, lmax);
        prof_subset = rtp_sub_prof(prof_subset, saveinds);
        fprintf(1, 'Done ***\n');
    end

    rtp_out_fn = sprintf('%s_%s.rtp', rtp_out_fn_head, asType{1,1});;
    rtp_outname = fullfile(airixcal_out_dir,num2str(iYear), asType{1,1}, rtp_out_fn);
    rtpwrite(rtp_outname,head,hattr,prof_subset,pattr);
    clear prof_subset

end  % for i=1:chunk


