function [head, hattr, prof, pattr] = create_airixcal_rtp(inpath, cfg)
%
% NAME
%   create_airixcal_rtp -- wrapper to process AIRIXCAL to RTP
%
% SYNOPSIS
%   create_airixcal_rtp(inpath, cfg)
%
% INPUTS
%   cfg   - OPTIONAL struct containing misc information

%
% REQUIRES:
%      /asl/packages/rtp_prod2_PROD/airs, util, grib, emis
%      /asl/packages/swutil
func_name = 'create_airixcal_rtp';

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
% Read the AIRIXCAL file *************************
fprintf(1, '>>> Reading input file: %s   ', inpath);
[prof, pattr, aux] = read_airixcal(inpath);
fprintf(1, 'Done\n');
%*************************************************

% $$$ %*************************************************
% $$$ % Pull out clear flagged obs (Flagged by AIRIXCAL algorithms) and
% $$$ % subset to fit rtp write limits
% $$$ % AIRIXCAL files contain too many obs for subsequent rtp2 writes (for
% $$$ % klayers/sarta/final output). They are also a mix of
% $$$ % clear/site/dcc/random obs. Select clear obs and Trim the dataset
% $$$ % here to avoid problems later (can probably make this one rtp_sub_prof)
% $$$ maxobs = 60000;
% $$$ iclear = find(bitget(prof.iudef(1,:),1)); % clear obs
% $$$ prof = rtp_sub_prof(prof, iclear);  
% $$$ saveinds = randperm(length(prof.rtime), maxobs);
% $$$ prof = rtp_sub_prof(prof, saveinds);
% $$$ clear saveinds
% $$$ %*************************************************

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
        {'header' 'rundate' trace.RunDate}, ...
        {'header' 'klayers' trace.klayers_exec}, ...
        {'header' 'sartaclr' trace.sartaclr_exec}, ...
        {'header' 'sartacld' trace.sartacld_exec} };
%*************************************************

%*************************************************
% rtp data massaging *****************************
% Fix for zobs altitude units
if isfield(prof,'zobs')
    prof = fix_zobs(prof);
end
%*************************************************

%*************************************************
% *** What data checks do we need ? **************
%*************************************************
% $$$ nobs = length(prof.robs1);
% $$$ for iobsidx = [1:1000:nobs]
% $$$     iobsblock = [iobsidx:min(iobsidx+999,nobs)];
% $$$     [prof.calflag(:, iobsblock) cstr] = data_to_calnum_l1bcm( ...
% $$$         aux.nominal_freq, aux.NeN, aux.CalChanSummary, ...
% $$$         matchedcalflag(:,  iobsblock), ...
% $$$         prof.rtime(:, iobsblock), prof.findex(:, iobsblock));
% $$$ end
% $$$ clear aux matchedcalflag;  % reclaiming some memory
% $$$ fprintf(1, 'Done\n');
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

%*************************************************
%**** Confirm these aren't necessary *************
%*************************************************
% Don't use Sergio's SST fix for now
% $$$ [head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);

% Don't need topography for AIRS, built-in
% $$$ [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);
% ************************************************


%*************************************************
% Add surface emissivity *************************
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_add_emis...');
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

% *** Should this change over to use driver_sarta_cloud? ***

%*************************************************
% run klayers ************************************
fprintf(1, '>>> running klayers... ');
fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               sTempPath '/kout.txt'];
unix(klayers_run);
fprintf(1, 'Done\n');
%*************************************************

%*************************************************
% Run sarta **************************************
fprintf(1, '>>> Running sarta... ');
fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
sarta_run = [sartaclr_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
               ' > ' sTempPath '/sartaout.txt'];
unix(sarta_run);
fprintf(1, 'Done\n');

% Read in new rcalcs and insert into origin prof field
stFileInfo = dir(fn_rtp3);
fprintf(1, ['*************\n>>> Reading fn_rtp3:\n\tName:\t%s\n\tSize ' ...
            '(GB):\t%f\n*************\n'], stFileInfo.name, stFileInfo.bytes/1.0e9);
[h,ha,p,pa] = rtpread(fn_rtp3);
prof.rcalc = p.rcalc;
head.pfields = 7;
% temporary files are no longer needed. delete them to make sure we
% don't fill up the scratch drive.
delete(fn_rtp1, fn_rtp2, fn_rtp3);
%*************************************************

fprintf(1, 'Done\n');


            