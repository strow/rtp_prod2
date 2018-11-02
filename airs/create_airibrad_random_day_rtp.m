function [head, hattr, prof, pattr] = create_airibrad_random_day_rtp(inpath, cfg)
%   create_airibrad_random_day_rtp -- wrapper to process AIRIBRAD to RTP
%
% SYNOPSIS
%   [head,hattr,prof,pattr] = create_airibrad_random_day_rtp(inpath, cfg)
%
% INPUTS
%    inpath :   path to input AIRIBRAD hdf file
%    cfg    :   configuration struct (OPTIONAL)
%
% OUTPUTS
%    head   :   rtp header struct
%    hattr  :   rtp header attribute cell array
%    prof   :   rtp profile struct
%    pattr  :   rtp profile attributes cell array
%
%    *In the event of failure, the rtp structs will be returned
%    empty*
%
% REQUIRES
%    swutils  :  githash
%
% DISCUSSION (TBD)
% This version operates on a day of AIRIBRAD granules
% and concatenates the subset of random obs into a single output file
% >> inpath is the path to an AIRS day of data
% /asl/data/airs/AIRIBRAD/<year>/<doy>
func_name = 'create_airibrad_random_day_rtp';

%*************************************************
% Execute user-defined paths *********************
REPOBASEPATH = '/home/sbuczko1/git/';
% $$$ REPOBASEPATH = '/asl/packages/';

PKG = 'rtp_prod2_PROD';
addpath(sprintf('%s/%s/util', REPOBASEPATH, PKG));
addpath(sprintf('%s/%s/grib', REPOBASEPATH, PKG));
addpath(sprintf('%s/%s/emis', REPOBASEPATH, PKG));
addpath(genpath(sprintf('%s/%s/airs', REPOBASEPATH, PKG)));

PKG = 'swutils'
addpath(sprintf('%s/%s', REPOBASEPATH, PKG));

PKG = 'matlib';
addpath(sprintf('%s/%s/clouds/sarta', REPOBASEPATH, PKG));  % driver_cloudy_sarta

addpath('/asl/matlib/rtptools');   % for cat_rtp
addpath('/asl/matlib/aslutil');    % for int2bits
%*************************************************

%*************************************************
% Build configuration ****************************
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sartaclr_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';
sartacld_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_iceGHMbaum_waterdrop_desertdust_slabcloud_hg3';
%*************************************************

model = 'era'; 
% read in configuration (if present) and modify defaults
if nargin == 2   % config structure present
    if isfield(cfg, 'klayers_exec')
        klayers_exec = cfg.klayers_exec;
    end
    if isfield(cfg, 'sartaclr_exec')
        sarta_exec = cfg.sartaclr_exec;
    end
    if isfield(cfg, 'sartacld_exec')
        sartacld_exec = cfg.sartacld_exec;
    end
    if isfield(cfg, 'model')
        model = cfg.model;
    end
end

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
% Read in day of granules and concatenate to single rtp structure set
head=struct;hattr={};prof=struct;pattr={};  % initialize output
                                            % vars empty so there
                                            % is something to
                                            % return even in event
                                            % of failure

% build list of hdf granule files for the day
files = dir(fullfile(inpath, '*.hdf'));
if isempty(files)
    fprintf(2, ['>> ERROR :: No granule files found in %s.\n>> ' ...
                'EXITING\n'], inpath);
    return;
end
fprintf(1, '>>> Found %d granule files to be read\n', ...
        length(files));

for i=1:length(files)
    % Read the AIRIBRAD file
    infile = fullfile(inpath, files(i).name);
    fprintf(1, '>>> Reading input file: %s   ', infile);
    try
        [eq_x_tai, freq, prof0, pattr] = read_airibrad(infile);
    catch
        fprintf(2, ['>>> ERROR: failure in read_airibrad for granule %s. ' ...
                    'Skipping.\n'], infile);
        continue;
    end
    fprintf(1, 'Done\n');

    if i == 1 % only need to build the head structure once but, we do
              % need freq data read in from first data file
              % Header 
        head.pfields = 4;  % robs1, no calcs in file
        head.ptype = 0;    
        head.ngas = 0;

        % Assign header attribute strings
        hattr={ {'header' 'pltfid' 'Aqua'}, ...
                {'header' 'instid' 'AIRS'}, ...
                {'header' 'githash' trace.githash}, ...
                {'header' 'rundate' trace.RunDate}, ...
                {'header' 'klayers_exec' klayers_exec}, ...
                {'header' 'sartaclr_exec' sartaclr_exec}, ...
                {'header' 'sarta_cld_exec' sartacld_exec} };

        nchan = size(prof0.robs1,1);
        chani = (1:nchan)';
        %vchan = aux.nominal_freq(:);
        vchan = freq;

        % Assign header variables
        head.instid = 800; % AIRS 
        head.pltfid = -9999;
        head.nchan = length(chani);
        head.ichan = chani;
        head.vchan = vchan(chani);
        head.vcmax = max(head.vchan);
        head.vcmin = min(head.vchan);

        % profile attribute changes for airibrad
        pattr = set_attr('profiles', 'robs1', infile);
        pattr = set_attr(pattr, 'rtime', 'TAI:1958');

    end  % end if i == 1

        p = equal_area_nadir_select(prof0,cfg);  % select for
                                                 % random/nadir obs
        fprintf(1, '>>>> SAVING %d random obs from granule\n', ...
                length(p.rlat));
        
        if i == 1
            prof = p;
        else
            % concatenate new random rtp data into running random rtp structure
            [head, prof] = cat_rtp(head, prof, head, p);
        end
end  % end for i=1:length(files)
clear prof0 p;

%*********************************************

%*************************************************
% rtp data massaging *****************************
% Fix for zobs altitude units
if isfield(prof,'zobs')
    prof = fix_zobs(prof);
end

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

head.pfields = 5;
fprintf(1, 'Done\n');
%*************************************************

%*************************************************
% Add surface emissivity *************************
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_add_emis...');
try
    [prof,pattr] = rtp_add_emis(prof,pattr);
catch
    fprintf(2, '>>> ERROR: rtp_add_emis failure for %s/%s\n', sYear, ...
            sDoy);
    return;
end
fprintf(1, 'Done\n');
%*************************************************

%*************************************************
% Save the rtp file ******************************
fprintf(1, '>>> Saving first rtp file... ');
[sID, sTempPath] = genscratchpath();
fn_rtp1 = fullfile(sTempPath, ['airs_random' sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr)
fprintf(1, 'Done\n');
%*************************************************
% call klayers/sarta cloudy **********************
fprintf(1, '>>> Running driver_sarta_cloud for both klayers and sarta\n');
run_sarta.cloud=+1;
run_sarta.clear=+1;
run_sarta.cumsum=9999;
% driver_sarta_cloud_rtp ultimately looks for default sarta
% executables in Sergio's directories. **DANGEROUS** These need to
% be brought under separate control for traceability purposes.
% $$$ try
[prof0, oslabs] = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);

% NEED ERROR CHECKING

% pull calcs out of prof0 and stuff into pre-klayers prof
[~,~,prof,~] = rtpread(fn_rtp1);
prof.rclr = prof0.rclr;
prof.rcld = prof0.rcld;

%*************************************************
% Make head reflect calcs
head.pfields = 7;  % robs, model, calcs


fprintf(1, 'Done\n');

        
