function [head, hattr, prof, pattr] = create_airxbcal_allfov_rtp(inpath, ...
                                                  cfg)
%
% NAME
%   create_airxbcal_allfov_rtp -- wrapper to process AIRXBCAL to RTP
%
% SYNOPSIS
%   create_airxbcal_allfov_rtp(inpath, cfg)
%
% INPUTS
%   inpath  :  path to AIRXBCAL daily data file
%   cfg     :  configuration structure
%
% REQUIRES:
%      /asl/packages/rtp_prod2_PROD/airs, util, grib, emis
%      /asl/packages/swutil
func_name = 'create_airxbcal_allfov_rtp';

%*************************************************
% Execute user-defined paths *********************
REPOBASEPATH = '/home/sbuczko1/git/';
% $$$ REPOBASEPATH = '/asl/packages/';

PKG = 'rtp_prod2_PROD';
addpath(sprintf('%s/%s/util', REPOBASEPATH, PKG);
addpath(sprintf('%s/%s/grib', REPOBASEPATH, PKG);
addpath(sprintf('%s/%s/emis', REPOBASEPATH, PKG);
addpath(genpath(sprintf('%s/%s/airs', REPOBASEPATH, PKG)));

PKG = 'swutils'
addpath(sprintf('%s/%s', REPOBASEPATH, PKG);
%*************************************************

%*************************************************
% Build configuration ****************************
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sartaclr_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';
sartacld_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_iceGHMbaum_waterdrop_desertdust_slabcloud_hg3
%*************************************************

%*************************************************
% Build traceability info ************************
trace.klayers = klayers_exec;
trace.sartaclr = sartaclr_exec;
trace.sartacld = sartacld_exec;
trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);
%*************************************************

%*************************************************
% Read the AIRXBCAL file *************************
fprintf(1, '>>> Reading input file: %s   ', fnfull);
[prof, pattr, aux] = read_airxbcal(fnfull);
fprintf(1, 'Done\n');
%*************************************************

% subset if nobs is greater than threshold lmax (to avoid hdf file size
% limitations and hdfvs() failures during rtp write/read
% later). Keeps dcc, site and random obs intact and reduces number
% of clear obs to meet threshold limit
lmax = 72000;
fprintf(1, '>>> *** %d pre-subset obs ***\n', length(prof.rtime));
if length(prof.rtime) > lmax
    fprintf(1, '>>>*** nobs > %d. subsetting clear... ', lmax);
    prof = sub_airxbcal(prof, lmax);
    fprintf(1, 'Done ***\n');
    fprintf(1, '>>> *** %d subset obs ***\n', length(prof.rtime));
end

%*************************************************
% Build out rtp structs **************************
nchan = size(prof.robs1,1);
chani = (1:nchan)';
vchan = aux.nominal_freq(:);

% Header 
head = struct;
head.pfields = 4;  % robs1, no calcs in file
head.ptype = 0;    
head.ngas = 0;
head.instid = 800; % AIRS 
head.pltfid = -9999;
head.nchan = length(chani);
head.ichan = chani;
head.vchan = vchan(chani);
head.vcmax = max(head.vchan);
head.vcmin = min(head.vchan);

% Assign header attribute strings
hattr={ {'header' 'pltfid' 'Aqua'}, ...
        {'header' 'instid' 'AIRS'}, ...
        {'header' 'githash' trace.githash}, ...
        {'header' 'rundate' trace.RunDate} };

%*************************************************

%*************************************************
% rtp data massaging *****************************
% Fix for zobs altitude units
if isfield(prof,'zobs')
    prof = fix_zobs(prof);
end
%*************************************************

%*************************************************
% Add in Scott's calflag *************************
% **** Requires running accessory script to get cal info from airibrad
% **** files for this day 
fprintf(1, '>>> Matching calflags... ');
[status, tmatchedcalflag] = mkmatchedcalflag(airs_year, airs_doy, ...
                                            prof);
if status == 99
    fprintf(1, ['>>> *** Corrupt meta data file. Terminating ' ...
                'processing\n']); 
    return;
elseif status == 98
    fprintf(1, ['>>> *** Calflag meta data file missing. Terminating ' ...
                'processing\n']);
    return;
end

matchedcalflag = transpose(tmatchedcalflag);
clear tmatchedcalflag;

nobs = length(prof.robs1);
for iobsidx = [1:1000:nobs]
    iobsblock = [iobsidx:min(iobsidx+999,nobs)];
    [prof.calflag(:, iobsblock) cstr] = data_to_calnum_l1bcm( ...
        aux.nominal_freq, aux.NeN, aux.CalChanSummary, ...
        matchedcalflag(:,  iobsblock), ...
        prof.rtime(:, iobsblock), prof.findex(:, iobsblock));
end
clear aux matchedcalflag;  % reclaiming some memory
fprintf(1, 'Done\n');
%*************************************************

%*************************************************
% Add in model data ******************************
fprintf(1, '>>> Add model: %s...', cfg.model)
switch cfg.model
  case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
  case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
end
% check that we have same number of model entries as we do obs because
% corrupt model files will leave us with an unbalanced rtp
% structure which WILL fail downstream (ideally, this should be
% checked for in the fill_* routines but, this is faster for now)
[~,nobs] = size(prof.robs1);
[~,mobs] = size(prof.gas_1);
if mobs ~= nobs
    fprintf(2, ['*** ERROR: number of model entries does not agree ' ...
                'with nobs ***\n'])
    return;
end
clear nobs mobs
head.pfields = 5;  % robs, model
fprintf(1, 'Done\n');
%*************************************************

% Don't use Sergio's SST fix for now
% [head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);

% Don't need topography for AIRS, built-in
% [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

%*************************************************
% Add surface emissivity *************************
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_ad_emis...');
[prof,pattr] = rtp_add_emis(prof,pattr);
fprintf(1, 'Done\n');
%*************************************************

%*************************************************
% Save the rtp file ******************************
fprintf(1, '>>> Saving first rtp file... ');
[sID, sTempPath] = genscratchpath();
fn_rtp1 = fullfile(sTempPath, ['airs_' sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr)
fprintf(1, 'Done\n');
%*************************************************

%*************************************************
% run klayers ************************************
fprintf(1, '>>> running klayers... ');
fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               sTempPath '/kout.txt'];
unix(klayers_run);
hattr{end+1} = {'header' 'klayers' klayers_exec};
fprintf(1, 'Done\n');
%*************************************************

%*************************************************
% Run sarta **************************************
fprintf(1, '>>> Running sarta... ');
fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
               ' > ' sTempPath '/sartaout.txt'];
unix(sarta_run);
fprintf(1, 'Done\n');
%*************************************************

%*************************************************
% Read in new rcalcs and insert into origin prof field
stFileInfo = dir(fn_rtp3);
fprintf(1, ['*************\n>>> Reading fn_rtp3:\n\tName:\t%s\n\tSize ' ...
            '(GB):\t%f\n*************\n'], stFileInfo.name, stFileInfo.bytes/1.0e9);
[h,ha,p,pa] = rtpread(fn_rtp3);
prof.rcalc = p.rcalc;
head.pfields = 7;
hattr{end+1} = {'header' 'sarta' sarta_exec};

% temporary files are no longer needed. delete them to make sure we
% don't fill up the scratch drive.
delete(fn_rtp1, fn_rtp2, fn_rtp3);
%*************************************************

fprintf(1, 'Done\n');


            