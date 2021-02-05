function [head, hattr, prof, pattr] = create_rtp_climcaps(fnCrisInput, ...
                                                  cfg)
% process a CLIMCAPS SNDR file
%
% script takes in a path to a day of granule files and loops over
% them to read and concatenate and rtp-safe random file
%
% input granule names are of the form:
% SNDR.SNPP.CRIMSS.20180717T1124.m06.g115.L2_CLIMCAPS_CCR.std.v02_28.G.200227223609.nc

fprintf(1, '>> Running create_rtp_climcaps for input: %s\n', ...
        fnCrisInput);

%[sID, sTempPath] = genscratchpath();
sID = getenv('SLURM_ARRAY_TASK_ID')
sTempPath = sprintf('/scratch/%s', getenv('SLURM_JOB_ID'))

% read in configuration options from 'cfg'
fprintf(1, '>>> Configuring default and runtime options\n');
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sartaclr_exec = '/home/chepplew/gitLib/sarta/bin/crisg4_oct16_aug20';

model = 'era';
nguard = 2;  % number of guard channels
nsarta = 4;  % number of sarta guard channels
asType = {'random'};
outputdir = '/umbc/isilon/rs/strow/asl/rtp/climcaps_snpp_ccr';
gran_stride=1;
if nargin == 2
    if isfield(cfg, 'klayers_exec')
        klayers_exec = cfg.klayers_exec;
    end
    if isfield(cfg, 'sartaclr_exec')
        sartaclr_exec = cfg.sartaclr_exec;
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
fnLst1 = dir(fullfile(fnCrisInput, '*.nc')); 
numgrans = numel(fnLst1);
if numgrans == 0
    fprintf(2, ['>>>> ERROR: No granules found for day %s. ' ...
                'Exiting.\n'], fnCrisInput);
    return;
end

fprintf(1,'>>> Found %d granule files to process\n', numgrans);
bFirstGranRead = false;
for i=1:gran_stride:numel(fnLst1)
    % try reading the granule files and concatenate piles for
    % each granule read
    fpath = fullfile(fnCrisInput,fnLst1(i).name);
    fprintf(1, '>>> Reading granule #%d/%d: %s\n', i, numgrans, fpath);


    % Load up rtp
    opt.resmode = cfg.resmode;
    [h, ha, prof0, pa] = climcaps2rtp(fpath, opt);

% $$$     temp = size(h.ichan);
% $$$     if temp(2) > 1
% $$$         h.ichan = h.ichan';
% $$$     end
% $$$     temp = size(h.vchan);
% $$$     if temp(2) > 1
% $$$         h.vchan = h.vchan';
% $$$     end

    % filter out desired FOVs/scan angles
    fprintf(1, '>>> Running get_equal_area_sub_indices for random selection... \n');
    fors = [1:30];

    nadir = ismember(prof0.xtrack,fors);

    % rtp has a 2GB limit so we have to scale number of kept FOVs
    % to stay within that as an absolute limit. Further, we
    % currently restrict obs count in random to ~20k to match
    % historical AIRXBCAL processing
    limit = 80000;  % number of obs to keep
    nswath = 45;  % length of ccast granules
    ngrans = 240;  % number of granules per day
    nfovs = 1;  % number of FOVs per FOR
    maxobs = nswath * length(fors) * nfovs * ngrans;
    scale = (limit/maxobs)*1.6; % preserves ~65k obs/day 
    randoms = get_equal_area_sub_indices(prof0.rlat, scale);
    nrinds = find(nadir & randoms);
    if length(nrinds) == 0
        return
    end
    p = rtp_sub_prof(prof0, nrinds);
    clear prof0
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
        prof = rtp_cat_prof(prof, p);
    end

end % end loop over granules

    % Need this later
    ichan_ccast = head.ichan;

    % Add profile data
    fprintf(1, '>>> Add model: %s...', cfg.model)
    switch cfg.model
      case 'ecmwf'
        [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
      case 'era'
        [prof,head,pattr]  = fill_era(prof,head,pattr);
      case 'era5'
        [prof,head,pattr]  = fill_era5(prof,head,pattr);
      case 'merra'
        [prof,head,pattr]  = fill_merra(prof,head,pattr);
    end

    head.pfields = 5;  % robs, model
    [nchan,nobs] = size(prof.robs1);
    head.nchan = nchan;
    head.ngas=2;


    % Add landfrac, etc.
    fprintf(1, '>>> Running usgs_10dem... ');
    [head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof, ...
                                                   pattr);
    fprintf(1, 'Done\n');

    % Add Dan Zhou's emissivity and Masuda emis over ocean
    % Dan Zhou's one-year climatology for land surface emissivity and
    % standard routine for sea surface emissivity
    fprintf(1, '>>> Running rtp_ad_emis...');
    [prof,pattr] = rtp_add_emis(prof,pattr);
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
    fn_rtp3 = fullfile(sTempPath, ['cris_' sID '_3.rtp']);
    run_sarta = [sartaclr_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ' > ' ...
                 sTempPath '/sarta_' sID '_stdout.txt'];
    fprintf(1, '>>> Running sarta: %s ...', run_sarta);
    unix(run_sarta);
    fprintf(1, 'Done\n');

    % Read in new rcalcs and insert into origin prof field
    fprintf(1, '>>> Reading sarta output... ');
    [head, hattr, p, pattr] = rtpread(fn_rtp3);
    fprintf(1, 'Done\n');

    % Insert rcalc and return to caller
    prof.rclr = p.rcalc;
    head.pfields = 7;


