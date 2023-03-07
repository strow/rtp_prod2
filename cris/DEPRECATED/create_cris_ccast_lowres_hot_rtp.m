function create_cris_ccast_lowres_hot_rtp(inpath,cfg)
% PROCESS_CRIS_LOWRES process one granule of CrIS data
%
% Process a single CrIS .mat granule file.

%set_process_dirs;

fprintf(1, '>> Running create_cris_ccast_lowres_rtp for input: %s\n', ...
        inpath);

bSaveComplex = false;
if isfield(cfg, 'bSaveComplex') & cfg.bSaveComplex == true
    bSaveComplex = true;
end

addpath /home/sbuczko1/git/rtp_prod2/cris/readers  % ccast2rtp
% $$$ addpath /home/sbuczko1/git/ccast/motmsc/rtp_sarta  % ccast2rtp;
addpath(genpath('/asl/matlib'));
% Need these two paths to use iasi2cris.m in iasi_decon
addpath /asl/packages/iasi_decon
addpath /asl/packages/ccast/source
% $$$ addpath /asl/packages/rtp_prod2/cris
addpath /home/sbuczko1/git/rtp_prod2/cris
% $$$ addpath /asl/packages/rtp_prod2/util
addpath /home/sbuczko1/git/rtp_prod2/util
addpath /asl/packages/rtp_prod2/emis
addpath /asl/packages/rtp_prod2/grib

[sID, sTempPath] = genscratchpath();
sID = getenv('SLURM_ARRAY_TASK_ID');
nguard = 2;  % nmbuer of guard channels

% build input/output filename info from inpath
% $$$ % /asl/data/cris/ccast/sdr60/2016/153/SDR_d20160601_t0006523.mat
C = strsplit(inpath, '/');
sYear = C{7};
sDoy = C{8};

% read in list of SDR files for day
files = dir(fullfile(inpath, '*.mat'));

for i=1:length(files)
    % read ccast sdr granule file
    infile = fullfile(inpath, files(i).name);
    fprintf(1, '>>> Reading input file: %s  ', infile);

    try
        [head, hattr, prof0, pattr] = ccast2rtp(infile, nguard);
    catch
        fprintf(2, '>>> ERROR: ccast2rtp failed for %s\n', ...
                infile);
        continue;
    end

    temp = size(head.ichan);
    if temp(2) > 1
        head.ichan = head.ichan';
    end
    temp = size(head.vchan);
    if temp(2) > 1
        head.vchan = head.vchan';
    end

    
    % find hot scenes and subset out
    btthresh = 335;  % 335K BT min for inclusion
    idtest_lw = 400:407;
    idtest_sw = 1285:1297;
    ib = hot_scene_check(head, prof0, btthresh, idtest_lw, ...
                         idtest_sw);
    fprintf(1, '>>> Found %d hot scenes in %s\n', length(ib), infile);
    if (length(ib) > 0)
        p = rtp_sub_prof(prof0, ib);
    else
        continue;
    end
    clear prof0;
    
    % if hot obs were found, stuff them into daily
    % rtp. Otherwise, next granule
    if (length(p.rtime) ~= 0)
        if (~exist('prof'))
            prof = p;
            clear p;
        else
            prof1 = prof;
            % concatenate new random rtp data into running random rtp structure
            [head, prof] = cat_rtp(head, prof1, head, p);
            clear prof1 p;
        end
    end
end % end read of granule files

    % quick sanity check on existence of prof struct and profiles
    % inside
    if (~exist('prof') | (exist('prof') & length(prof.rtime) < 1))
        fprintf(2, '*** No hot obs found for %s/%s\n', sYear, ...
                sDoy);
        return;
    end
    
    
    % Add profile data
    fprintf(1, '>>> Add model: %s...', cfg.model)
    switch cfg.model
      case 'ecmwf'
        [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
      case 'era'
        [prof,head,pattr]  = fill_era(prof,head,pattr);
      case 'merra'
        [prof,head,pattr]  = fill_merra(prof,head,pattr);
    end
    head.pfields = 5;

    [nchan,nobs] = size(prof.robs1);
    head.nchan = nchan;
    head.ngas=2;
    fprintf(1, 'Done\n');


    % Add landfrac, etc.
    fprintf(1, '>>> Running usgs_10dem... ');
    [head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof, ...
                                                   pattr);
    fprintf(1, 'Done\n');

    % Add Dan Zhou's emissivity and Masuda emis over ocean
    % Dan Zhou's one-year climatology for land surface emissivity and
    % standard routine for sea surface emissivity
    fprintf(1, '>>> Running add_emis... ');
    [prof,pattr] = rtp_add_emis_single(prof,pattr);
    fprintf(1, 'Done\n');


    % Make directory if needed
    % cris lowres data will be stored in
    % /asl/data/rtp_cris_ccast_lowres/{clear,dcc,site,random}/<year>/<doy>
    %
% $$$ cris_out_dir = '/asl/rtp/rtp_cris_ccast_lowres';
    cris_out_dir = '/home/sbuczko1/WorkingFiles/rtp_cris_ccast_lowres';
    % Make directory if needed
    sPath = fullfile(cris_out_dir,char(cfg.type),sYear);
    if exist(sPath) == 0
        mkdir(sPath);
    end

    fprintf(1, '>> Prepping output\n');
    fprintf(1, '>> OUTPUT : Valid obs found :: %d\n', length(prof.rtime));
    rtp_out_fn = sprintf('cris_lr_%s_d%s%s_%s.rtp',cfg.model, sYear, ...
                         sDoy, char(cfg.type));
    rtp_outname = fullfile(sPath, rtp_out_fn);
    rtpwrite(rtp_outname,head,hattr,prof,pattr);
    
    fprintf(1, 'Done\n');