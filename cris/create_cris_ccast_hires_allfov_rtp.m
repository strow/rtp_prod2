function [head, hattr, prof, pattr] = create_cris_ccast_hires_allfov_rtp(fnCrisInput, cfg)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS hires .mat granule file.
funcname = 'create_cris_ccast_hires_allfov_rtp';

fprintf(1, '>> Running %s for input: %s\n', funcname, fnCrisInput);

addpath(genpath('/asl/matlib'));
% Need these two paths to use iasi2cris.m in iasi_decon
addpath /asl/packages/iasi_decon
addpath /asl/packages/ccast/source
addpath /asl/packages/ccast/motmsc/rtp_sarta  % ccast2rtp
addpath /asl/matlib/aslutil   % int2bits
addpath /asl/packages/time    % iet2tai (in ccast2rtp)
addpath /asl/packages/rtp_prod2/cris;  % ccast2rtp
addpath /asl/packages/rtp_prod2/grib;  % fill_era/ecmwf
addpath /asl/packages/rtp_prod2/emis;  % add_emis
addpath /asl/packages/rtp_prod2/util;  % rtpread/write
addpath /home/sbuczko1/git/matlib/clouds/sarta  %
                                                % driver_cloud... (version
                                                % in /asl/matlib
                                                % has typos)

[sID, sTempPath] = genscratchpath();

% read in configuration options from 'cfg'
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
% $$$ sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
% $$$                'sarta_iasi_may09_wcon_nte'];
sarta_exec = '/asl/bin/crisg4_oct16';
sartacld_exec = ['/home/sbuczko1/git/sarta/bin/' ...
                 'sarta_apr08_m140_iceGHMbaum_waterdrop_desertdust_slabcloud_hg3X']; 
nguard = 2;  % number of guard channels
nsarta = 4;  % number of sarta guard channels
model = 'era';
if nargin == 2
    if isfield(cfg, 'klayers_exec')
        klayers_exec = cfg.klayers_exec;
    end
    if isfield(cfg, 'sarta_exec')
        sarta_exec = cfg.sarta_exec;
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
    asType = {'allfov'};
    if isfield(cfg, 'SaveType')
        asType = cfg.SaveType;
    end
    outputdir = '/asl/rtp/rtp_cris_ccast_hires';
    if isfield(cfg, 'outputdir')
        outputdir = cfg.outputdir;
    end
    if isfield(cfg, 'model')
        model = cfg.model;
    end
end  % end if nargin == 2

% Load up rtp
[head, hattr, prof, pattr] = ccast2rtp(fnCrisInput, nguard, nsarta);

% check ichan index order (to avoid problems with rtpwrite)
temp = size(head.ichan);
if temp(2) > 1
    head.ichan = head.ichan';
end
temp = size(head.vchan);
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
fprintf(1, '>>> Add model: %s...', model)
switch model
  case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
  case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
end

% rtp now has profile and obs data ==> 5
head.pfields = 5;
[nchan,nobs] = size(prof.robs1);
head.nchan = nchan;
head.ngas=2;
fprintf(1, 'Done\n');

% Add landfrac, etc.
fprintf(1, '>>> Running rtpadd_usgs_10dem...');
[head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);
fprintf(1, 'Done\n');

% Add Dan Zhou's emissivity and Masuda emis over ocean
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_add_emis_single...');
[prof0,pattr] = rtp_add_emis_single(prof,pattr);
fprintf(1, 'Done\n');

% run driver_sarta_cloud to handle klayers and sarta runs
run_sarta.clear=+1;
run_sarta.cloud=+1;
run_sarta.cumsum=-1;
run_sarta.klayers_code = klayers_exec;
run_sarta.sartaclear_code = sarta_exec;
run_sarta.sartacloud_code = sartacld_exec;

prof = driver_sarta_cloud_rtp(head, hattr, prof0, pattr, ...
                               run_sarta);

end  % end function




