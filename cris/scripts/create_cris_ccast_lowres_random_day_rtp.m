function create_cris_ccast_lowres_random_day_rtp(fnCrisInput, cfg)
% CREATE_CRIS_CCAST_LOWRES_RANDOM_DAY_RTP process one day's worth of granules of CrIS data
% concatenate each granule into a single daily rtp file and subset
% for random

% read in mat files found in a single day of CRiS SDR60 files
% produced at UMBC by Howard Motteler. As each granule is read in,
% find the random subset and concatenate to a
% running structure of subset obs. once a day of granules is
% assembled, run klayers and sarta and output rtp.

% Current directory structure puts CRiS sdr granule data under:
% /asl/data/cris/ccast/sdr60/<YYYY>/<DOY>

% Current granule filenaming convention under the directories
% above:
func_name = 'create_cris_ccast_lowres_random_day_rtp';

addpath /home/sbuczko1/git/ccast/motmsc/rtp_sarta  % ccast2rtp (L1b
                                                   % Q/A update not
                                                   % pushed out to /asl/packages)
addpath /home/sbuczko1/git/matlib/clouds/sarta  %
                                                % driver_cloud... (version
                                                % in /asl/matlib
                                                % has typos)
addpath /home/sbuczko1/git/rtp_prod2/cris  % hha_lat_subsample_...
addpath /asl/matlib/rtptools  % cat_rtp.m
addpath /asl/matlib/aslutil   % int2bits
addpath /asl/packages/time    % iet2tai (in ccast2rtp)

addpath /asl/packages/rtp_prod2/util
addpath /asl/packages/rtp_prod2/emis
addpath /asl/packages/rtp_prod2/grib

addpath('/home/sbuczko1/git/swutils');
trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

[sID, sTempPath] = genscratchpath();
sID = getenv('SLURM_ARRAY_TASK_ID')

% set defaults
nguard = 2;  % number of guard channels
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
               'sarta_crisg4_nov09_wcon_nte'];  %% lowres
sartacld_exec = ['/asl/packages/sartaV108/BinV201/' ...
                 'sarta_crisg4_nov09_iceGHMbaum_waterdrop_desertdust_slabcloud_hg3_wcon_nte'];

model = 'era'; % ERA-Interim

% read in configuration (if present) and modify defaults
if nargin == 2   % config structure present
    if isfield(cfg, 'nguard')
        nguard = cfg.nguard;
    end
    if isfield(cfg, 'klayers_exec')
        klayers_exec = cfg.klayers_exec;
    end
    if isfield(cfg, 'sarta_exec')
        sarta_exec = cfg.sarta_exec;
    end
    if isfield(cfg, 'sartacld_exec')
        sartacld_exec = cfg.sartacld_exec;
    end
    if isfield(cfg, 'model')
        model = cfg.model;
    end
end

fprintf(1, '>> %s Running create_cris_ccast_lowres_random_day_rtp for input: %s\n', ...
        char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);

% fnCrisInput is a path of the form:
% /asl/data/cris/ccast/sdr60/YYYY/DOY
% output will go to /asl/rtp/rtp_cris_ccast_lowres/YYYY
pathparts = strsplit(fnCrisInput, '/');
cris_yearstr=pathparts{end-1};  % grab YYYY from input path, needed
                                % for output path

% generate a list of the mat files in the the day pointed to by
% fnCrisInput
fnLst1 = dir(fullfile(fnCrisInput, 'SDR_d*_t*.mat')); 
numgrans = numel(fnLst1);
if numgrans ~= 0
    fprintf(1,'>>> %s Found %d granule files to process\n', ...
            char(datetime('now', 'Format', 'HHmmss')), numel(fnLst1));
else
    fprintf(2, ['>>> %s ERROR: No granules files found for day %s. ' ...
                'Exiting.\n'], char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);
    return;
end

nkeep = 0;  % random obs counter
bFirstGranRead = false;
for i=1:numel(fnLst1)
    % try reading the granule files and concatenate profiles for
    % each granule read
    fprintf(1, '>>> Granule %d\n', i);
    try
        [h, ha, p, pa] = ccast2rtp(fullfile(fnCrisInput,fnLst1(i).name), nguard);
    catch
        fprintf(2, ['>>> %s ERROR: ccast2rtp failure. Trying ' ...
                    'next granule\n'], char(datetime('now', 'Format', 'HHmmss')));
        continue;
    end

    % ensure that we have column vectors in h
    temp = size(h.ichan);
    if temp(2) > 1
        h.ichan = h.ichan';
    end
    temp = size(h.vchan); 
    if temp(2) > 1
        h.vchan = h.vchan';
    end

% $$$     % sarta puts limits on satzen/satang (satzen comes out in the
% $$$     % profiles form ccast2rtp) so, filter to remove profiles
% $$$     % outside this range to keep sarta from failing.
% $$$     inrange = find(p.satzen >= 0.0 & p.satzen < 63.0);
% $$$     prof = rtp_sub_prof(p, inrange);
% $$$     clear inrange;

% $$$     % create random subsample
% $$$     fprintf(1, '>>> Running hha_lat_subsample... ');
% $$$     [irand,irand2] = hha_lat_subsample_equal_area2_cris_hires(h, p);
% $$$     if numel(irand) == 0
% $$$         fprintf(2, ['>>> ERROR : No random obs returned. Skipping to ' ...
% $$$                     'next granule.\n'])
% $$$         continue;
% $$$     end
% $$$ 
% $$$     p = rtp_sub_prof(p, irand);

    % testing new get_equal_area_sub_indices selection code
    % need to select for nadir obs (xtrack == {15,16}
    fprintf(1, '>>> Running get_equal_area_sub_indices for random selection... ');
    p = rtp_sub_prof(p,find(p.xtrack == 15 | p.xtrack == 16));
    limit = 0.011*15;  % threshold for cutting down number of
                       % returned obs
    indl = get_equal_area_sub_indices(p.rlat, limit);
    p = rtp_sub_prof(p, find(indl));
    nkeep = nkeep + length(indl);
    fprintf(1, '>>> Done\n');
    
    % concatenate into a single daily rtp structure
    if ~bFirstGranRead % this is first good read. Take rtp structs
                       % as baseline for subsequent concatenation
        head = h;
        hattr = ha;
        prof = p;
        pattr = pa;
        
        bFirstGranRead = true;
    else
        [head, prof] = cat_rtp(head, prof, h, p);

    end
    
end  % end loop over mat files

fprintf(1, '>>> Found %d random obs via new get_equal_area code\n', ...
        nkeep);
    
% Add profile data
fprintf(1, '>>> Add model: %s...', model)
switch model
  case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
  case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
end
% rtp now has profile and obs data ==> 5
head.pfields = 5;
[nchan,nobs] = size(prof.robs1);
head.nchan = nchan;
head.ngas=2;
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% Add landfrac, etc.
fprintf(1, '>>> %s Running usgs_10dem...\n',char(datetime('now', 'Format', 'HHmmss')));
[head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof, pattr);
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% Add Dan Zhou's emissivity and Masuda emis over ocean
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> %s Running add_emis...\n',char(datetime('now', 'Format', 'HHmmss')));
[prof,pattr] = rtp_add_emis_single(prof,pattr);
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% run driver_sarta_cloud to handle klayers and sarta runs
run_sarta.clear=+1;
run_sarta.cloud=+1;
run_sarta.cumsum=-1;
run_sarta.klayers_code = klayers_exec;
run_sarta.sartaclear_code = sarta_exec;
run_sarta.sartacloud_code = sartacld_exec;

prof0 = driver_sarta_cloud_rtp(head, hattr, prof, pattr, ...
                               run_sarta);

% Make directory if needed
% cris lowres data will be stored in
% /asl/data/rtp_cris_ccast_lowres/{clear,dcc,site,random}/<year>/<doy>
%
asType = {'random'};
% $$$ cris_out_dir = '/asl/rtp/rtp_cris_ccast_lowres';
cris_out_dir = '/home/sbuczko1/WorkingFiles/rtp_cris_ccast_lowres';
for i = 1:length(asType)
    % check for existence of output path and create it if necessary. This may become a source
    % for filesystem collisions once we are running under slurm.
    sPath = fullfile(cris_out_dir,char(asType(i)),cris_yearstr);
    if exist(sPath) == 0
        mkdir(sPath);
    end
end
% $$$
% build output filename based on date stamp of input mat files
parts = strsplit(fnLst1(1).name, '_');
cris_datestr = parts{2};
rtp_out_fn = ['cris_lr_' model '_' cris_datestr '_' asType{1} '.rtp'];

% Now save the cris files
nobs = numel(prof0.rlat);
rtp_outname = fullfile(sPath, rtp_out_fn);
fprintf(1, '>>> %s writing %d profiles to output rtp file\n\t%s ... ', ...
        char(datetime('now', 'Format', 'HHmmss')), nobs, rtp_outname);
rtpwrite(rtp_outname,head,hattr,prof0,pattr);
fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));

