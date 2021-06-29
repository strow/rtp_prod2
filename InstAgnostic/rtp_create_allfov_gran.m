function [head, hattr, prof, pattr, trace] = rtp_create_allfov_gran(granfile, cfg)
%
% NAME
%    rtp_create_allfov_gran
%
% SYNOPSIS
%    [head,hattr,prof,pattr] = rtp_create_allfov_gran(granfile,cfg);
%
% INPUTS
%    granfile : full path to granule file to process
%    cfg : config struct containing all processing information and
%          instrument-specific settings
%
% OUTPUTS
%    head : RTP head structure conforming to RTP V2.01 spec
%    (https://asl.umbc.edu/helppages/packages/rtpspec201/)
%    hattr : RTP V2.01 header attributes cell array
%    prof : RTP V2.01 struct of profiles
%    pattr : RTP V2.01 profile attributes cell array
%    trace : struct of traceability information for run
%
% S. Buczkowski 2021-06-29
%    Based on previous work by L. Strow, S. Hannon, H. Motteler,
%    P. Schou, and S. DeSouza-Machado
%
% DISCUSSION (TBD)
func_name = 'rtp_create_allfov_gran';

% establish local directory structure
currentFilePath = mfilename('fullpath');
[cfpath, cfname, cfext] = fileparts(currentFilePath);
fprintf(1,'> Executing routine: %s\n', currentFilePath);

%*************************************************
% Build configuration ****************************
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
% Read the granule file *************************
fprintf(1, '>>> Reading input file: %s   ', granfile);
[h,ha,p,pa] = rtp_read_granule(granfile, cfg);
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

%*******
% Run klayers and sarta (both clear and cloudy)
% 
[h,ha,p,pa] = rtp_run_klayers_sarta(h,ha,p,pa);

fprintf(1, 'Done\n');


