function [head, hattr, prof, pattr] = ...
    create_airicrad_allfov_gran_rtp(inpath, cfg)
%
% NAME
%   create_airicrad_allfov_gran_rtp -- wrapper to process AIRICRAD to RTP
%
% SYNOPSIS
%   create_airicrad_allfov_gran_rtp(infile, outfile_head)
%
% INPUTS
%    infile :   path to input AIRICRAD hdf file
%    outfile_head  : path to output rtp file (minus extension)
%
% L. Strow, Jan. 14, 2015
%
% DISCUSSION (TBD)
func_name = 'create_airicrad_allfov_gran_rtp';

% establish local directory structure
currentFilePath = mfilename('fullpath');
[cfpath, cfname, cfext] = fileparts(currentFilePath);
fprintf(1,'> Executing routine: %s\n', currentFilePath);

%*************************************************
% Build configuration ****************************
% $$$ klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
% $$$ sartaclr_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';
% $$$ sartacld_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_iceGHMbaum_waterdrop_desertdust_slabcloud_hg3';
klayers_exec = cfg.klayers_exec;
sartaclr_exec   = cfg.sartaclr_exec;
sartacld_exec   = cfg.sartacld_exec;
%*************************************************

%*************************************************
% Build traceability info ************************
trace.klayers = klayers_exec;
trace.sartaclr = sartaclr_exec;
trace.sartacld = sartacld_exec;
[status, trace.githash] = githash();
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);
%*************************************************

%*************************************************
% Read the AIRICRAD file *************************
fprintf(1, '>>> Reading input file: %s   ', inpath);
[eq_x_tai, freq, prof, pattr] = read_airicrad(inpath);
fprintf(1, 'Done\n');
%*************************************************

%*************************************************
% Build out rtp structs **************************
nchan = size(prof.robs1,1);
% $$$ chani = (1:nchan)'; % need to change to reflect proper sarta ichans
% $$$                     % for chan 2378 and higher
% following line loads array 'ichan' which gets swapped for chani below
load(fullfile(cfpath, 'static/sarta_chans_for_l1c.mat'));

%vchan = aux.nominal_freq(:);
vchan = freq;

% Header 
head = struct;
head.pfields = 4;  % robs1, no calcs in file
head.ptype = 0;    % levels
head.ngas = 0;
head.instid = 800; % AIRS 
head.pltfid = -9999;
head.nchan = length(ichan); % was chani
head.ichan = ichan;  % was chani
head.vchan = vchan; % was vchan(chani)
head.vcmax = max(head.vchan);
head.vcmin = min(head.vchan);

% hattr
hattr={ {'header' 'pltfid' 'Aqua'}, ...
        {'header' 'instid' 'AIRS'}
        {'header' 'githash' trace.githash}, ...
        {'header' 'rundate' trace.RunDate} };

% profile attribute changes for airicrad
pattr = set_attr(pattr, 'robs1', inpath);
pattr = set_attr(pattr, 'rtime', 'TAI:1958');

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
  case 'era5'
    [prof,head,pattr]  = fill_era5(prof,head,pattr);
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

% call klayers/sarta cloudy
run_sarta.cloud=cfg.sarta_cld;
run_sarta.clear=cfg.sarta_clr;
run_sarta.cumsum=cfg.sarta_cumsum;
run_sarta.klayers_code=klayers_exec;
run_sarta.sartaclear_code=sartaclr_exec;
run_sarta.sartacloud_code=sartacld_exec;

[prof0, oslabs] = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);

% NEED ERROR CHECKING
% pull calcs out of prof0 and stuff into pre-klayers prof
[~,~,prof,~] = rtpread(fn_rtp1);
prof.rclr = prof0.rclr;
prof.rcld = prof0.rcld;

% also capture cloud fields
prof.cfrac = prof0.cfrac;   
prof.cfrac12 = prof0.cfrac12; 
prof.cfrac2 = prof0.cfrac2;  
prof.cngwat = prof0.cngwat;  
prof.cngwat2 = prof0.cngwat2; 
prof.cprbot = prof0.cprbot;  
prof.cprbot2 = prof0.cprbot2; 
prof.cprtop = prof0.cprtop;  
prof.cprtop2 = prof0.cprtop2; 
prof.cpsize = prof0.cpsize;  
prof.cpsize2 = prof0.cpsize2; 
prof.ctype = prof0.ctype;   
prof.ctype2 = prof0.ctype2;  
prof.co2ppm = prof0.co2ppm;

%*************************************************

%*************************************************
% Make head reflect calcs
head.pfields = 7;  % robs, model, calcs

fprintf(1, 'Done\n');


