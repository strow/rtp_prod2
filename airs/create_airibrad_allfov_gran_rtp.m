function [head, hattr, prof, pattr] = create_airibrad_allfov_gran_rtp(inpath, cfg)
%
% NAME
%   create_airibrad_allfov_gran_rtp -- wrapper to process AIRIBRAD to RTP
%
% SYNOPSIS
%   create_airibrad_allfov_gran_rtp(inpath, cfg)
%
% INPUTS
%    inpath :   path to input AIRIBRAD hdf file
%    cfg    :   configuration structure
%
% REQUIRES:
%   rtp_prod2_PROD/{util,grib,emis}
%   matlib
%
% DISCUSSION (TBD)
func_name = 'create_airibrad_allfov_gran_rtp';

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
% Read the AIRIBRAD file *************************
fprintf(1, '>>> Reading input file: %s   ', inpath);
[eq_x_tai, freq, prof, pattr] = read_airibrad(inpath);
fprintf(1, 'Done\n');

%*************************************************
% Build out rtp structs **************************
nchan = size(prof.robs1,1);
chani = (1:nchan)';
%vchan = aux.nominal_freq(:);
vchan = freq;

% Header 
head = struct;
head.pfields = 4;  % robs1, no calcs in file
head.ptype = 0;    % levels
head.ngas = 0;
head.instid = 800; % AIRS 
head.pltfid = -9999;
head.nchan = length(chani);
head.ichan = chani;
head.vchan = vchan(chani);
head.vcmax = max(head.vchan);
head.vcmin = min(head.vchan);

% Hattr
hattr={ {'header' 'pltfid' 'Aqua'}, ...
        {'header' 'instid' 'AIRS'}
        {'header' 'githash' trace.githash}, ...
        {'header' 'rundate' trace.RunDate} };

% profile attribute changes for airibrad
pa = set_attr('profiles', 'robs1', inpath);
pa = set_attr(pa, 'rtime', 'TAI:1958');

%*************************************************

%*************************************************
% rtp data massaging *****************************
% Fix for zobs altitude units
if isfield(prof,'zobs')
    prof = fix_zobs(prof);
end
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

%*************************************************
% klayers/sarta **********************************
fprintf(1, ['>>> Running driver_sarta_cloud for both klayers and ' ...
            'sarta\n']);
run_sarta.cloud=+1;
run_sarta.clear=+1;
run_sarta.cumsum=9999;
% driver_sarta_cloud_rtp ultimately looks for default sarta
% executables in Sergio's directories. **DANGEROUS** These need to
% be brought under separate control for traceability purposes.
% $$$ try
[prof0, oslabs] = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);

% NEED ERROR CHECKING

%*************************************************
% Make head reflect calcs
head.pfields = 7;  % robs, model, calcs

fprintf(1, 'Done\n');


