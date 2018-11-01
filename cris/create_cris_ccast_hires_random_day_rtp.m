function [head, hattr, prof, pattr] = create_cris_ccast_hires_random_day_rtp(fnCrisInput, cfg)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS hires .mat granule file.
funcname = 'create_cris_ccast_hires_random_day_rtp';

fprintf(1, '>> Running %s for input: %s\n', funcname, fnCrisInput);

addpath /home/sbuczko1/git/rtp_prod2/cris/util
addpath /home/sbuczko1/git/rtp_prod2/emis;  % add_emis
addpath /home/sbuczko1/git/rtp_prod2/util;  % rtpread/write
addpath /home/sbuczko1/git/rtp_prod2/grib;  % fill_era/ecmwf
addpath /asl/matlib/rtptools  % cat_rtp.m
addpath /asl/matlib/aslutil   % int2bits
addpath /asl/packages/time    % iet2tai (in ccast2rtp)
addpath /home/sbuczko1/git/ccast/motmsc/rtp_sarta  % ccast2rtp
addpath /home/sbuczko1/git/ccast/source  % fixmyQC
addpath /home/sbuczko1/git/matlib/clouds/sarta  %
                                                % driver_cloud... (version
                                                % in /asl/matlib
                                                % has typos)

[sID, sTempPath] = genscratchpath();
fprintf(1, '>>> Job PROCID = %s\nTEMP Directory = %s\n',sID, ...
        sTempPath);

cfg.sID = sID;
cfg.sTempPath = sTempPath;

% read in configuration options from 'cfg'
fprintf(1, '>>> Configuring default and runtime options\n');
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec = '/asl/bin/crisg4_oct16';
sartacld_exec = ['/asl/bin/' ...
                 'crisg4_hires_dec17_iceGHMbaum_waterdrop_desertdust_slabcloud_hg3'];
model = 'era';
nguard = 2;  % number of guard channels
nsarta = 4;  % number of sarta guard channels
asType = {'random'};
outputdir = '/asl/rtp/rtp_cris_ccast_hires';
gran_stride=1;
if nargin == 2
    if isfield(cfg, 'klayers_exec')
        klayers_exec = cfg.klayers_exec;
    end
    if isfield(cfg, 'sarta_exec')
        sarta_exec = cfg.sarta_exec;
    end
    if isfield(cfg, 'sartacld_exec')
        sartacld_exec = cfg.sartacld_exec;
    end
    if isfield(cfg, 'nguard')
        nguard = cfg.nguard;
    end
    if isfield(cfg, 'nsarta')
        nsarta = cfg.nsarta;
    end
    % check for validity of guard channel specifications
    if nguard > nsarta
        fprintf(2, ['*** Too many guard channels requested/specified ' ...
                    '(nguard/nsarta = %d/%d)***\n'], nguard, nsarta);
        return
    end
    if isfield(cfg, 'SaveType')
        asType = cfg.SaveType;
    end
    if isfield(cfg, 'outputdir')
        outputdir = cfg.outputdir;
    end
    if isfield(cfg, 'model')
        model = cfg.model;
    end
    if isfield(cfg, 'gran_stride')
        gran_stride = cfg.gran_stride;
    end
end  % end if nargin == 2


% generate a list of the mat files in the the day pointed to by
% fnCrisInput
fprintf(1, '>>> Generating list of input granule files.\n');
fnLst1 = dir(fullfile(fnCrisInput, '*.mat')); 
numgrans = numel(fnLst1);
if numgrans == 0
    fprintf(2, ['>>>> ERROR: No granules found for day %s. ' ...
                'Exiting.\n'], fnCrisInput);
    return;
end

% char(datetime('now', 'Format', 'HHmmss'))  makes time string of
% current time

fprintf(1,'>>> Found %d granule files to process\n', numgrans);
bFirstGranRead = false;
for i=1:gran_stride:numel(fnLst1)
    % try reading the granule files and concatenate piles for
    % each granule read
    fpath = fullfile(fnCrisInput,fnLst1(i).name);
    fprintf(1, '>>> Reading granule #%d/%d: %s\n', i, numgrans, fpath);
    try
        [h,ha,p,pa] = ccast2rtp(fpath, nguard);
    catch
        fprintf(2, ['>>>> ERROR: ccast2rtp failure reading %s.\n\t\tTrying ' ...
                    'next granule\n'], fpath);
        continue;
    end
    if length(p.rtime) == 0
        fprintf(2, 'WARNING >> No obs found in granule %s\n', fpath);
        return
    end
    fprintf(1, '>>> Read %d obs from granule\n', length(p.rtime));

    % check ichan index order (to avoid problems with rtpwrite)
    temp = size(h.ichan);
    if temp(2) > 1
        h.ichan = h.ichan';
    end
    temp = size(h.vchan);
    if temp(2) > 1
    h.vchan = h.vchan';
    end

    % filter out desired FOVs/scan angles
    fprintf(1, '>>> Running get_equal_area_sub_indices for random selection... \n');
    fors = [1:30];

    nadir = ismember(p.xtrack,fors);

    % rtp has a 2GB limit so we have to scale number of kept FOVs
    % to stay within that as an absolute limit. Further, we
    % currently restrict obs count in random to ~20k to match
    % historical AIRXBCAL processing
    limit = 20000;  % number of obs to keep
    nswath = 45;  % length of ccast granules
    ngrans = 240;  % number of granules per day
    nfovs = 9;  % number of FOVs per FOR
    maxobs = nswath * length(fors) * nfovs * ngrans;
    scale = (limit/maxobs)*1.6; % preserves ~65k obs/day 
    randoms = get_equal_area_sub_indices(p.rlat, scale);
    nrinds = find(nadir & randoms);
    if length(nrinds) == 0
        return
    end
    p = rtp_sub_prof(p, nrinds);
    fprintf(1, '>>> Found %d obs after random selection\n', length(p.rtime));

    % build sub satellite lat point
    [p, pa] = build_satlat(p,pa);

    % Need this later
    ichan_ccast = h.ichan;

    % now that we've trimmed off many (most?) of the obs,
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

end % end loop over granules
    
% Add profile data
fprintf(1, '>>> Add model: %s...', model)
switch model
  case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr,cfg);
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
fprintf(1, 'Done\n');

% Add landfrac, etc.
fprintf(1, '>>> Running rtpadd_usgs_10dem...');
[head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);
fprintf(1, 'Done\n');

% Add Dan Zhou's emissivity and Masuda emis over ocean
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_add_emis_single...');
[prof,pattr] = rtp_add_emis_single(prof,pattr);
fprintf(1, 'Done\n');

% $$$ % run driver_sarta_cloud to handle klayers and sarta runs
sarta_cfg.clear=+1;
sarta_cfg.cloud=+1;
sarta_cfg.cumsum=+9999;
sarta_cfg.klayers_code = klayers_exec;
sarta_cfg.sartaclear_code = sarta_exec;
sarta_cfg.sartacloud_code = sartacld_exec;

prof = driver_sarta_cloud_rtp(head, hattr, prof, pattr, ...
                              sarta_cfg);

end  % end function




