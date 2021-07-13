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

% establish local directory structure
currentFilePath = mfilename('fullpath');
[cfpath, cfname, cfext] = fileparts(currentFilePath);
fprintf(1,'* Executing routine: %s\n', currentFilePath);

%*************************************************
% Build traceability info ************************
trace.klayers = cfg.klayers_exec;
trace.sartaclr = cfg.sartaclr_exec;
trace.sartacld = cfg.sartacld_exec;
[status, trace.githash] = githash();
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '* Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);
%*************************************************

%*************************************************
% Read the granule file *************************
fprintf(1, '** Reading input granule file: %s...   ', granfile);
[head,hattr,prof,pattr] = rtp_read_granule(granfile, cfg);
if isempty(fieldnames(prof))
    fprintf(1, 'FAILED\n');
    return
end
fprintf(1, 'SUCCEEDED\n');
%*************************************************

%*************************************************
% Add in model data ******************************
fprintf(1, '** Add model: %s...', cfg.model)
[head, hattr, prof, pattr] = rtp_add_model(head, hattr, prof, pattr, ...
                                           cfg);
if isempty(fieldnames(prof))
    fprintf(1, 'FAILED\n');
    return
end
fprintf(1, 'SUCCEEDED\n');
%*************************************************

%*************************************************
% Add DEM surface model **************************
fprintf(1, '** Running rtp_add_dem...');
[head, hattr, prof, pattr] = rtp_add_dem(head,hattr,prof, pattr, cfg);
% Are there any failure modes likely in this section?
fprintf(1, 'SUCCEEDED\n');
%*************************************************

%*************************************************
% Add surface emissivity *************************
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '** Running rtp_add_emis...');
[head, hattr, prof, pattr] = rtp_add_emis(head, hattr,prof,pattr, cfg);
% Are there any failure modes likely in this section?
fprintf(1, 'SUCCEEDED\n');
%*************************************************

%*************************************************
% Run klayers and sarta (both clear and cloudy)
% 
fprintf(1, '** Running klayers and sarta (clear and cloudy)...');
[head,hattr,prof,pattr] = rtp_run_klayers_sarta(head,hattr,prof,pattr, ...
                                                cfg);
if isempty(fieldnames(prof))
    fprintf(1, 'FAILED\n');
    return
end
fprintf(1, 'SUCCEEDED\n');
%*************************************************

fprintf(1. '* Run terminated successfully %s\n', ...
        char(datetime('now','TimeZone','local','Format',
                         'd-MMM-y HH:mm:ss Z'));



