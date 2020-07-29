function create_cris_ccast_lr_nn_random_day(fnCrisInput, cfg)
% CREATE_CRIS_CCAST_LR_NN_RANDOM_DAY select random nadir 1231cm-1
% obs along with nearest-neighbors

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

fprintf(1, '>> %s Running create_cris_ccast_lr_nn_random_day for input: %s\n', ...
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

    % We need the leading and trailing FORs around FORs 15&16 later
    % so, filter those out now and set aside
    fprintf(1, '>>> Subsetting FORs 14-17\n');
    p = rtp_sub_prof(p, find(p.xtrack == 14 | p.xtrack == 15 | ...
                             p.xtrack == 16 | p.xtrack == 17));
    
    % ultimately only need single radiance but must
    % apodize with the neighboring lines first
    % Apply Hamming apodization to radiances
    % Convert rbox to rham
    [nchan, nobs] = size(p.robs1);
    rham = p.robs1;
    ii = 2:(nchan-1);
    ilo = ii-1;
    ihi = ii+1;
    rham(ii,:) = 0.23*(p.robs1(ilo,:) + p.robs1(ihi,:)) + 0.54*p.robs1(ii,:);
    % replace radiances with Hamming apodized radiance in the
    % 1231cm-1 line (2-guard channel array index 737/sarta channel
    % ID 731)
% $$$     schanID=731;
    % 901.875cm-1 line (2-guard channel array index 406/sarta
    % channel ID 404)
% $$$     schanID=404; % sarta channel number
    % 901.875cm-1 line (2-guard channel array index 1304/sarta
    % channel ID 1294)
    schanID=1294; % sarta channel number
    chanind = find(h.ichan == schanID);
    p.robs1 = rham(chanind,:);
    h.ichan = h.ichan(chanind);
    h.vchan = h.vchan(chanind);
    h.nchan = 1;
    
    % ensure that we have column vectors in h
    temp = size(h.ichan);
    if temp(2) > 1
        h.ichan = h.ichan';
    end
    temp = size(h.vchan); 
    if temp(2) > 1
        h.vchan = h.vchan';
    end

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

% testing new get_equal_area_sub_indices selection code
% need to select for nadir obs (xtrack == {15,16}
fprintf(1, '>>> Running get_equal_area_sub_indices for random selection... ');
p = rtp_sub_prof(prof,find(prof.xtrack == 15 | prof.xtrack == 16));
limit = 0.011*15;  % threshold for cutting down number of
                   % returned obs
indl = get_equal_area_sub_indices(p.rlat, limit);
p = rtp_sub_prof(p, find(indl));
nkeep = sum(indl);
fprintf(1, '>>> Done\n');

% build LUT for nearest-neighbor FOVs
% Neighbor table for nadir
%
% [FOR,FOV,FOR,FOV]
% nn = nnLUT(p.xtrack-14, p.ifov,:)
nnLUT(2,1,:) = [16 2 15 3];
nnLUT(2,2,:) = [16 3 16 1];
nnLUT(2,3,:) = [17 1 16 2];
nnLUT(2,4,:) = [16 5 15 6];
nnLUT(2,5,:) = [16 6 16 4];
nnLUT(2,6,:) = [17 4 16 5];
nnLUT(2,7,:) = [16 8 15 9];
nnLUT(2,8,:) = [16 9 16 7];
nnLUT(2,9,:) = [17 7 16 8];

nnLUT(1,1,:) = [15 2 14 3];
nnLUT(1,2,:) = [15 3 15 1];
nnLUT(1,3,:) = [16 1 15 2];
nnLUT(1,4,:) = [15 5 14 6];
nnLUT(1,5,:) = [15 6 15 4];
nnLUT(1,6,:) = [16 4 15 5];
nnLUT(1,7,:) = [15 8 14 9];
nnLUT(1,8,:) = [15 9 15 7];
nnLUT(1,9,:) = [16 7 15 8];

tobs = zeros(3, length(p.rtime),'single');
mindex = ones(1, length(p.rtime));
fprintf(1,'>>> length(mindex) = %d\n', length(mindex));
for i = 1:length(p.rtime)
    nn = squeeze(nnLUT(p.xtrack(i)-14,p.ifov(i),:))';
    % nn now has [FOR FOV FOR FOV] for the leading and following
    % obs
    % xtrack, ifov and atrack are not unique across granules so, we
    % need to also add additional selection information to make
    % unique matches (rtime, rlat/rlon, granuleID (p.iudef(3,:)))
    
    % find index for obs in FOR preceding (leading) the selected obs
    lindex = find(prof.xtrack==nn(3) & prof.ifov==nn(4) & ...
                  prof.atrack==p.atrack(i) & prof.iudef(3,:)==p.iudef(3,i));
    % find index for obs in FOR following (trailing) the selected obs
    tindex = find(prof.xtrack==nn(1) & prof.ifov==nn(2) & ...
                  prof.atrack==p.atrack(i) & prof.iudef(3,:)==p.iudef(3,i));

    % now grab robs1 from prof for these indices and concatenate
    % into p.robs1 (FOVs can go missing between the spacecraft and
    % here so, this is only if t/lindex match to a valid obs)
    if ~length(lindex) | ~length(tindex)
        mindex(i) = 0;
        tobs(:,i) = cat(1, NaN, NaN, NaN);
    else
        tobs(:,i) = cat(1, p.robs1(1,i), prof.robs1(1, lindex), ...
                        prof.robs1(1,tindex));
    end
    
end
p.robs1 = tobs;
fprintf(1, '>>> nobs before missing FOV check: %d\n', length(p.rtime));
p = rtp_sub_prof(p, find(mindex));
fprintf(1, '>>> nobs after missing FOV check: %d\n', ...
        length(p.rtime));

fprintf(1, '>>> Found %d random obs via new get_equal_area code\n', ...
        length(p.rtime));
    
% Add profile data
fprintf(1, '>>> Add model: %s...', model)
switch model
  case 'ecmwf'
    [p,h,pa]  = fill_ecmwf(p,h,pa);
  case 'era'
    [p,h,pa]  = fill_era(p,h,pa);
  case 'merra'
    [p,h,pa]  = fill_merra(p,h,pa);
end
% rtp now has profile and obs data ==> 5
head.pfields = 5;
[nchan,nobs] = size(p.robs1);
h.nchan = nchan;
h.ngas=2;
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% Add landfrac, etc.
fprintf(1, '>>> %s Running usgs_10dem...\n',char(datetime('now', 'Format', 'HHmmss')));
[h, ha, p, pa] = rtpadd_usgs_10dem(h,ha,p, pa);
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% Add Dan Zhou's emissivity and Masuda emis over ocean
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> %s Running add_emis...\n',char(datetime('now', 'Format', 'HHmmss')));
[p,pa] = rtp_add_emis_single(p,pa);
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% $$$ % run driver_sarta_cloud to handle klayers and sarta runs
% $$$ run_sarta.clear=+1;
% $$$ run_sarta.cloud=+1;
% $$$ run_sarta.cumsum=-1;
% $$$ run_sarta.klayers_code = klayers_exec;
% $$$ run_sarta.sartaclear_code = sarta_exec;
% $$$ run_sarta.sartacloud_code = sartacld_exec;
% $$$ 
% $$$ prof0 = driver_sarta_cloud_rtp(head, hattr, prof, pattr, ...
% $$$                                run_sarta);

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
rtp_out_fn = sprintf('cris_lr_%s_%s_%s-smear-ch%d.rtp', model, ...
                     cris_datestr, asType{1}, schanID);

% Now save the cris files
nobs = numel(p.rlat);
rtp_outname = fullfile(sPath, rtp_out_fn);
fprintf(1, '>>> %s writing %d profiles to output rtp file\n\t%s ... ', ...
        char(datetime('now', 'Format', 'HHmmss')), nobs, rtp_outname);
rtpwrite(rtp_outname,h,ha,p,pa);
fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));


