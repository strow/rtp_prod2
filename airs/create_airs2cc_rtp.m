function [head, hattr, prof, pattr] = create_airs2cc_rtp(inpath, cfg)
%
% NAME
%   create_airs2cc_rtp -- wrapper to process AIRIBRAD to RTP
%
% SYNOPSIS
%   create_airs2cc_rtp(infile, cfg)
%
% INPUTS
%    infile :   path to input AIRIBRAD hdf file
%    cfg :  structure of configuration options to overide defaults
%
% OUTPUTS
%    head : rtp header struct
%    hattr : rtp header attribute cell array
%    prof : rtp profile struct
%    pattr : rtp profile attribute cell array
%
% REQUIRES
%    
% DISCUSSION (TBD)
func_name = 'create_airs2cc_rtp';

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
sartacld_exec   = ['/asl/packages/sartaV108/BinV201/' ...
 ...
                   'sarta_apr08_m140_iceGHMbaum_waterdrop_desertdust_slabcloud_hg3']
model = 'era';
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
[sID, sTempPath] = genscratchpath();
%*************************************************


if nargin == 2 % cfg structure present to overide defaults
    if isfield(cfg, 'klayers_exec')
        klayers_exec = cfg.klayers_exec;
    end
    if isfield(cfg, 'sarta_exec')
        sarta_exec = cfg.sarta_exec;
    end
    if isfield(cfg, 'model')
        model = cfg.model;
    end
end



%*************************************************
% Read the AIRS2CCF file *************************
fprintf(1, '>>> Reading input file: %s   ', inpath);
[eq_x_tai, freq, prof, pattr] = v6_readl2cc(inpath);
fprintf(1, 'Done\n');
%*************************************************

%*************************************************
% Build out rtp structs **************************
nchan = size(prof.robs1,1);
chani = (1:nchan)';
vchan = freq;

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
        {'header' 'klayers_exec' klayers_exec}, ...
        {'header' 'sarta_exec' sarta_exec} };

% Assign profile attribute strings
% $$$ pattr={ {'' '' ''} };
% profile attribute changes for airibrad
% $$$ pattr = set_attr('profiles', 'robs1', infile);
% $$$ pattr = set_attr(pattr, 'rtime', 'TAI:1958');

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
% run klayers ************************************
fprintf(1, '>>> running klayers... ');
fn_rtp1 = fullfile(sTempPath, ['airs_' sID '_1.rtp']);
rtpwrite(fn_rtp1, head, hattr, prof, pattr);
fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               sTempPath '/kout.txt'];
unix(klayers_run);
fprintf(1, 'Done\n');

%*************************************************
% Run sarta **************************************
fprintf(1, '>>> Running sarta... ');
fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
               ' > ' sTempPath '/sartaout.txt'];
unix(sarta_run);
fprintf(1, 'Done\n');
%*************************************************

% read in post-sarta results
[h,ha,p,pa] = rtpread(fn_rtp3);

% restore pre-klayers prof and insert sarta calcs
[head, hattr, prof, pattr] = rtpread(fn_rtp1);
prof.rcalc = p.rcalc;


fprintf(1, 'Done\n');

            
