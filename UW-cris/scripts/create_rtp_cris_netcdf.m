function [head, hattr, prof, pattr] = create_rtp_cris_netcdf(fnCrisInput, ...
                                                  cfg)
% CREATE_UWCRIS_LOWRES_RTP process one granule of UW CrIS data
%
% Process a single UW CrIS netcdf granule file and produce a set of
% allfov rtp structures
%
% REQUIRES
%
% input granule names are of the form:
% SNDR.SNPP.CRIS.20160120T2206.m06.g222.L1B_NSR.std.v01_00_00.W.160311163941.nc

fprintf(1, '>> Running create_rtp_cris_netcdf for input: %s\n', ...
        fnCrisInput);

klayers_exec = cfg.klayers_exec;
sarta_exec = '


[sID, sTempPath] = genscratchpath();
sID = getenv('SLURM_ARRAY_TASK_ID');
nguard = 2;  % number of guard channels


% Load up rtp
opt.resmode = cfg.resmode;;
[head, hattr, p, pattr] = uwnc2rtp(fnCrisInput, opt);

temp = size(head.ichan)
if temp(2) > 1
    head.ichan = head.ichan';
end
temp = size(head.vchan)
if temp(2) > 1
    head.vchan = head.vchan';
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% REMOVE THIS BEFORE PRODUCTION COMMIT     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% subset rtp for faster debugging
%%%% JUST GRAB THE FIRST 100 OBS
% $$$ fprintf(1, '>>> SUBSETTING PROF FOR DEBUG\n');
% $$$ iTest =(1:1000);
% $$$ prof_sub = prof;
% $$$ prof = rtp_sub_prof(prof_sub, iTest);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Need this later
ichan_ccast = head.ichan;

% Add profile data
fprintf(1, '>>> Add model: %s...', cfg.model)
switch cfg.model
  case 'ecmwf'
    [p,head,pattr]  = fill_ecmwf(p,head,pattr);
  case 'era'
    [p,head,pattr]  = fill_era(p,head,pattr);
  case 'era5'
    [p,head,pattr]  = fill_era5(p,head,pattr);
  case 'merra'
    [p,head,pattr]  = fill_merra(p,head,pattr);
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
% $$$ fprintf(1, '>>> Running add_emis... ');
% $$$ [prof,pattr] = rtp_add_emis_single(prof,pattr);
% $$$ fprintf(1, 'Done\n');

% Subset for quicker debugging
% prof = rtp_sub_prof(prof, 1:10:length(prof.rlat));

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
% $$$ fprintf(1, '>>> Reading klayers output... ');
% $$$ [head, hattr, prof, pattr] = rtpread(fn_rtp2);
fprintf(1, 'Done\n');

% Run sarta
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
[head, hattr, p, pattr] = rtpread(fn_rtp3);
fprintf(1, 'Done\n');

% Insert rcalc and return to caller
prof.rclr = p.rcalc;
head.pfields = 7;


