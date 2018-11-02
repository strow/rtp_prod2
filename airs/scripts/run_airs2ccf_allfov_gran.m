function  run_airs2ccf_allfov_gran()
% 
%
% read in a directory of rtp files (most likely constituting a day
% of data) and concatenate them into a single output rtp
% file. Calls cat_rtp_dir() which does the bulk of the actual
% concatenation. This routine drives input/output selection and
% does the final rtpwrite

addpath('~/git/rtp_prod2_PROD/airs');  % create_airs2cc_rtp
addpath('~/git/rtp_prod2_PROD/util');  % rtpread,rtpwrite


% 
airs_daily_file_list = '~/airs2ccf_grans_to_process';

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));
% $$$ slurmindex = 0;

% for each slurm array index, process 30 days from the to-process
% list (because each day takes less time to process than it takes
% to load matlab so, it is inefficient to do each day as a
% separate array)
chunk = 5;
for i = 1:chunk
    dayindex = (slurmindex*chunk) + i;

    fprintf(1, '>>> chunk %d    dayindex %d\n', i, dayindex);

    % inpath for AIRS2CCF is of the form
    % /asl/data/airs/AIRS2CCF/YYYY/DOY/AIRS.2016.01.18.067.L2.CC_IR.v6.0.31.0.G16018155843.hdf
    [status, inpath] = system(sprintf('sed -n "%dp" %s | tr -d "\n"', ...
                                     dayindex, airs_daily_file_list));
    if strcmp(inpath, '')
        break;
    end

    cfg.model = 'era';
    fprintf(1, '*** Using model %s\n', cfg.model);
    
    [h,ha,p,pa] = create_airs2cc_rtp(inpath, cfg);

    % rtpoutfile is of the form
    %       /asl/rtp/rtp_airs2ccf_v6/allfov/YYYY/DOY/airs2ccf_era_allfov_dYYYYDOY_GRAN.rtp
    %
    % YYYY & DOY come from inpath elements 6 & 7 after breaking on
    % '/'
    % GRAN comes from inpath element 8 and is element 5 after
    % breaking on '.'
    C = strsplit(inpath, '/');
    sYear = C{6};
    sDoy = C{7}
    C = strsplit(C{8}, '.');
    sGranNum = C{5}
    rtpoutfile = sprintf(['/asl/rtp/rtp_airs2ccf_v6/allfov/%s/%s/' ...
                        'airs2ccf_era_allfov_d%s%s_%s.rtp'], sYear, ...
                         sDoy, sYear, sDoy, sGranNum);
    fprintf(1, '>>> writing rtp output to %s\n', rtpoutfile);
    rtpwrite(rtpoutfile, h,ha,p,pa);
    fprintf(1, '>>> Done\n');
    
end  % ends loop over chunk
