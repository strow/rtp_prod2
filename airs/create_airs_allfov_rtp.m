function [head, hattr, prof, pattr] = ...
    create_airs_allfov_rtp(inpath, cfg)
%
% NAME
%   create_airicrad_allfov_rtp -- wrapper to process AIRICRAD to RTP
%
% SYNOPSIS
%   create_airicrad_allfov_rtp(infile, outfile_head)
%
% INPUTS
%    infile :   path to input AIRICRAD hdf file
%    outfile_head  : path to output rtp file (minus extension)
%*************************************************
mfilepath = mfilename('fullpath');
mp = fileparts(mfilepath);
fprintf(1, '>> Running %s for input: %s\n', mfilepath, infile);

[sID, sTempPath] = genscratchpath();
cfg.sID = sID;
cfg.sTempPath = sTempPath;

% Build traceability info ************************
trace.klayers = cfg.klayers_exec;
trace.sartaclr = cfg.sartaclr_exec;
trace.sartacld = cfg.sartacld_exec;
[status, trace.githash] = githash();
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                              'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);
%*************************************************

% read AIRS granule
cfg.airstype='airicrad';  % move into config scripts
[head,hattr,prof,pattr] = read_airs(inpath, cfg);

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


