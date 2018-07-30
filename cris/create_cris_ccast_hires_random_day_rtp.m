function [head, hattr, prof, pattr] = create_cris_ccast_hires_random_day_rtp(fnCrisInput, cfg)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS hires .mat granule file.
funcname = 'create_cris_ccast_hires_random_day_rtp';

fprintf(1, '>> Running %s for input: %s\n', funcname, fnCrisInput);

addpath(genpath('/asl/matlib'));
addpath /asl/matlib/aslutil   % int2bits
addpath /asl/packages/time    % iet2tai (in ccast2rtp)
addpath /home/sbuczko1/git/ccast/motmsc/rtp_sarta  % ccast2rtp
addpath /home/sbuczko1/git/rtp_prod2/grib;  % fill_era/ecmwf
addpath /asl/packages/rtp_prod2/emis;  % add_emis
addpath /asl/packages/rtp_prod2/util;  % rtpread/write
addpath /home/sbuczko1/git/matlib/clouds/sarta  %
                                                % driver_cloud... (version
                                                % in /asl/matlib
                                                % has typos)

[sID, sTempPath] = genscratchpath();

cfg.sID = sID;
cfg.sTempPath = sTempPath;

% read in configuration options from 'cfg'
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
% $$$ sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
% $$$                'sarta_iasi_may09_wcon_nte'];
sarta_exec = '/asl/bin/crisg4_oct16';
sartacld_exec = ['/asl/bin/' ...
                 'crisg4_hires_dec17_iceGHMbaum_waterdrop_desertdust_slabcloud_hg3'];
model = 'era';
nguard = 2;  % number of guard channels
nsarta = 4;  % number of sarta guard channels
asType = {'random'};
outputdir = '/asl/rtp/rtp_cris_ccast_hires';
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
end  % end if nargin == 2


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

    
bFirstGranRead = false;
for i=1:numel(fnLst1)
    % try reading the granule files and concatenate profiles for
    % each granule read
    try
        [h2, ha2, p2, pa2] = ccast2rtp(fullfile(fnCrisInput,fnLst1(i).name), nguard);
    catch
        fprintf(2, ['>>> %s ERROR: ccast2rtp failure. Trying ' ...
                    'next granule\n'], char(datetime('now', 'Format', 'HHmmss')));
        continue;
    end
    if length(prof.rtime) == 0
        return
    end

    % check ichan index order (to avoid problems with rtpwrite)
    temp = size(head.ichan);
    if temp(2) > 1
        head.ichan = head.ichan';
    end
    temp = size(head.vchan);
    if temp(2) > 1
    head.vchan = head.vchan';
    end

    % filter out desired FOVs/scan angles
    fprintf(1, '>>> Running get_equal_area_sub_indices for random selection... ');
% $$$ fors = [15 16];  % Indices for desired Fields of Regard (FOR)
    fors = [1:30];

    nadir = ismember(prof.xtrack,fors);

    % rtp has a 2GB limit so we have to scale number of kept FOVs
    % to stay within that as an absolute limit. Further, we
    % currently restrict obs count in random to ~20k to match
    % historical AIRXBCAL processing
    limit = 95000;  % number of obs to keep
    nswath = 45;  % length of ccast granules
    ngrans = 240;  % number of granules per day
    nfovs = 9;  % number of FOVs per FOR
    maxobs = nswath * length(fors) * nfovs * ngrans;
    scale = (limit/maxobs)*1.6; % preserves ~95k obs/day 
    randoms = get_equal_area_sub_indices(prof.rlat, scale);
    nrinds = find(nadir & randoms);
    if length(nrinds) == 0
        return
    end
    crprof = rtp_sub_prof(prof, nrinds);
    prof=crprof;
    clear crprof;

    % build sub satellite lat point
    [prof, pattr] = build_satlat(prof,pattr);

    % Need this later
    ichan_ccast = head.ichan;

    % now that we've trimmed off many (most?) of the obs,
    % concatenate into a single daily rtp structure
    if ~bFirstGranRead % this is first good read. Take rtp structs
                       % as baseline for subsequent concatenation
        h = h2;
        ha = ha2;
        p = p2;
        pa = pa2;
        
        bFirstGranRead = true;
    else
        [h, p] = cat_rtp(h, p, h2, p2);
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

% run klayers
fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
fprintf(1, '>>> Writing klayers input temp file %s ...', fn_rtp1);
rtpwrite(fn_rtp1,head,hattr,prof,pattr)
fprintf(1, 'Done\n')
fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
run_klayers=[klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath ...
             '/klayers_' sID '_stdout']
fprintf(1, '>>> Running klayers: %s ...', run_klayers);
unix([klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath ...
      '/klayers_' sID '_stdout'])
fprintf(1, 'Done\n');

% Run sarta
if strcmp('csarta', cfg.rta)
    % *** split fn_rtp3 into 'N' multiple chunks (via rtp_sub_prof like
    % below for clear,site,etc?) make call to external shell script to
    % run 'N' copies of sarta backgrounded
    fn_rtp3 = fullfile(sTempPath, ['cris_' sID '_3.rtp']);
    run_sarta = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ' > ' ...
                 sTempPath '/sarta_' sID '_stdout.txt'];
    fprintf(1, '>>> Running sarta: %s ...', run_sarta);
    unix(run_sarta);
    fprintf(1, 'Done\n');
    
    % Read in new rcalcs and insert into origin prof field
% $$$ stFileInfo = dir(fn_rtp3);
% $$$ fprintf(1, ['*************\n>>> Reading fn_rtp3:\n\tName:\t%s\n\tSize ' ...
% $$$             '(GB):\t%f\n*************\n'], stFileInfo.name, stFileInfo.bytes/1.0e9);
    fprintf(1, '>>> Reading sarta output... ');
    [h,ha,p,pa] = rtpread(fn_rtp3);
    fprintf(1, 'Done\n');
    
    % Go get output from klayers, which is what we want except for rcalc
% $$$ [head, hattr, prof, pattr] = rtpread(fn_rtp2);
% Insert rcalc for CrIS derived from IASI SARTA
    prof.rclr = p.rcalc;
    head.pfields = 7;
    
% $$$ 
% $$$ % run driver_sarta_cloud to handle klayers and sarta runs
    sarta_cfg.clear=+1;
    sarta_cfg.cloud=+1;
    sarta_cfg.cumsum=-1;
    sarta_cfg.klayers_code = klayers_exec;
    sarta_cfg.sartaclear_code = sarta_exec;
    sarta_cfg.sartacloud_code = sartacld_exec;
    
    prof = driver_sarta_cloud_rtp(head, hattr, prof, pattr, ...
                                  sarta_cfg);
else if strcmp('isarta', cfg.rta)
        [head, hattr, prof, pattr] = rtpread(fn_rtp2);
        [head, hattr, prof, pattr] = run_sarta_iasi(head, hattr, ...
                                                    prof, pattr, ...
                                                    cfg);
end

end  % end function




