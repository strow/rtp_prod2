function [head, hattr, prof, pattr] = create_cris_ADL_sdr_hires_clear_gran_rtp(fnCrisInput, cfg)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS .mat granule file.

fprintf(1, '>> Running create_cris_ccast_hires_rtp for input: %s\n', ...
        fnCrisInput);


% read in configuration options from 'cfg'
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
if isfield(cfg, 'klayers_exec')
    klayers_exec = cfg.klayers_exec;
end

sartaclr_exec = '/asl/bin/crisg4_oct16'; 
if isfield(cfg, 'sartaclr_exec')
    sartaclr_exec = cfg.sartaclr_exec;
end

nguard = 2;  % number of guard channels
if isfield(cfg, 'nguard')
    nguard = cfg.nguard;
end

nsarta = 4;  % number of sarta guard channels
if isfield(cfg, 'nsarta')
    nsarta = cfg.nsarta;
end

% check for validity of guard channel specifications
if nguard > nsarta
    fprintf(2, ['*** Too many guard channels requested/specified ' ...
                '(nguard/nsarta = %d/%d)***\n'], nguard, nsarta);
    return
end

addpath(genpath('/asl/matlib'));
% Need these two paths to use iasi2cris.m in iasi_decon
addpath /asl/packages/iasi_decon
addpath /asl/packages/ccast/source
addpath /home/sbuczko1/git/ccast/motmsc/utils  % read_SCRIF
addpath /asl/matlib/aslutil   % int2bits
% $$$ addpath /asl/packages/rtp_prod2/cris;  % ccast2rtp
addpath /home/sbuczko1/git/ccast/test % read_SCRIS

% $$$ addpath /asl/packages/rtp_prod2/grib;  % fill_era/ecmwf
addpath /home/sbuczko1/git/rtp_prod2_DEV/grib;  % fill_era/ecmwf
addpath /home/sbuczko1/git/rtp_prod2_DEV/emis;  % add_emis
addpath /home/sbuczko1/git/rtp_prod2_DEV/util;  % rtpread/write

addpath /home/sbuczko1/git/rtp_prod2_DEV/cris/readers % sdr read
                                                      % function

addpath /home/sbuczko1/git/rtp_prod2_DEV/cris/util  % build_satlat
addpath /home/sbuczko1/git/rtp_prod2_DEV/util  % genscratchpath
addpath /home/sbuczko1/git/rtp_prod2_DEV/util/time % time functions
addpath /home/sbuczko1/git/rtp_prod2_DEV/cris/util/uniform_clear

[sID, sTempPath] = genscratchpath();

% Load up rtp
[prof, pattr] = readsdr_rtp(fnCrisInput);

% load up profile attributes
% $$$ [~, ~, attr] = read_SCRIF(fnCrisInput);
% $$$ tmp=attr.Ascending_Descending_Indicator;
% $$$ if length(tmp) > 1
% $$$     fprintf(2, '** Multiple asc/desc indicators found **\n');
% $$$     return
% $$$ end
% $$$ prof.iudef(4,:) = ones(1,length(prof.rtime),'int32') * int32(tmp);
prof.iudef(4,:) = (prof.solzen < 90.0);

%-------------------
% set header values
%-------------------
head = struct;
load '/home/sbuczko1/git/rtp_prod2/cris/CrIS_ancillary'
head.nchan = nchan;
head.ichan = ichan;
head.vchan = vchan;
% $$$ head.ichan = cris_ichan(nguard, nsarta, nLW, nMW, nSW);
% $$$ head.vchan = cris_vchan(nguard, userLW, userMW, userSW);
head.pfields = 4; % 4 = IR obs

%-----------------------
% set header attributes
%-----------------------
hattr = {{'header', 'instid', 'CrIS'}, ...
         {'header', 'reader', 'readsdr_rtp'}, ...
        };

%*********
% cris_find_uniform is predicated on having a full 9x30x45
% granule. We may have to turn the following NaN check into
% a 'throw out this granule and continue to next' until
% things can be made more flexible
%*********
% check rtime values for NaN. subset out obs with such
% rtimes (in all such cases found so far, Nans are in a
% contiguous block and all profile fields are NaN'd)
gnans = isnan(prof.rtime);
nnans = sum(gnans);
nobs = length(prof.rtime);
if nnans | nobs ~= 16200        % for 60 scan files, 12150 for 45 scan files
    fprintf(2,'>> Granule %d contains NaNs or is wrong size. SKIPPING\n',i);
% $$$             nan_inds = find(~gnans);
% $$$             p_gran = rtp_sub_prof(p_gran,nan_inds);
    return;
end

% check pixel uniformity. If no FOR/FOVs satisfy
% uniformity, no point in continuing to process this
% granule
uniform_cfg = struct;
uniform_cfg.uniform_test_channel = 961;
uniform_cfg.uniform_bt_threshold = 0.4; 
uniform_cfg.scanlines = 60;
[iuniform, amax_keep] = cris_find_uniform(head, prof, uniform_cfg);

% subset out non-uniform FOVs
nuniform = length(iuniform);
if 0 == nuniform
    fprintf(2,['>> No uniform FOVs found for granule %d. ' ...
               'SKIPPING\n'],i)
    return;
end

fprintf(1, '>> Uniform obs found: %d/12150\n', nuniform);
prof = rtp_sub_prof(prof,iuniform);

% check that [iv]chan are column vectors
temp = size(head.ichan);
if temp(2) > 1
    head.ichan = head.ichan';
end
temp = size(head.vchan);
if temp(2) > 1
    head.vchan = head.vchan';
end

% Need this later
ichan_ccast = head.ichan;

% build sub-satellite lat point
[prof, pattr] = build_satlat(prof, pattr);

% Add profile data
switch cfg.model
  case 'ecmwf'
    [prof,head,pattr]=fill_ecmwf(prof,head,pattr,cfg);
  case 'era'
    [prof,head,pattr]=fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]=fill_merra(prof,head,pattr);    
end

% rtp now has profile and obs data ==> 5
head.pfields = 5;
[nchan,nobs] = size(prof.robs1);
head.nchan = nchan;
head.ngas=2;


% Add landfrac, etc.
[head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

% Add Dan Zhou's emissivity and Masuda emis over ocean
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_ad_emis...');
[prof,pattr] = rtp_add_emis_single(prof,pattr);
fprintf(1, 'Done\n');


% run klayers
fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr);
fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
unix([klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath '/klayers_stdout'])

% scale gas concentrations, if requested in config
if isfield(cfg, 'scaleco2') | isfield(cfg, 'scalech4')
    % read in klayers output
    [hh,hha,pp,ppa] = rtpread(fn_rtp2);
    delete fn_rtp2
    if isfield(cfg, 'scaleco2')
        pp.gas_2 = pp.gas_2 * cfg.scaleco2;
        pattr{end+1} = {'profiles' 'scaleCO2' sprintf('%f', cfg.scaleco2)};
    end
    if isfield(cfg, 'scalech4')
        pp.gas_6 = pp.gas_6 * cfg.scalech4;
        pattr{end+1} = {'profiles' 'scaleCH4' sprintf('%f', cfg.scalech4)};        
    end
    rtpwrite(fn_rtp2,hh,hha,pp,ppa)
end

% run sarta
    fprintf(1, '>>> Running sarta... ');
    fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
    sarta_run = [sartaclr_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
                 ' > ' sTempPath '/sartaout.txt'];
    unix(sarta_run);
    % read in sarta results to capture rcalc
    [~,~,p,~] = rtpread(fn_rtp3);
    prof.rclr = p.rcalc;
    clear p;

        % now that we have calcs, find clear FOVs
        iobs2check = 1:length(prof.rtime);
        [iflagsc, bto1232, btc1232] = xfind_clear_hires(head, prof, iobs2check);
        iclear_sea    = find(iflagsc == 0 & prof.landfrac <= 0.01);
        iclear_notsea = find(iflagsc == 0 & prof.landfrac >  0.01);
% $$$         iclear = union(iclear_sea, iclear_notsea);
        iclear = iclear_sea;
        nclear = length(iclear);
        fprintf(1, '>>>> Total of %d uniform obs passed clear test\n', nclear);
        prof = rtp_sub_prof(prof, iclear);

    fprintf(1, 'Done\n');

    
