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

addpath ~/git/swutils
addpath ~/git/rtp_prod2/util
addpath ~/git/rtp_prod2/airs/readers
addpath ~/git/rtp_prod2/grib
addpath ~/git/rtp_prod2/emis

% set some defaults
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = ['/asl/packages/sartaV108/BinV201/' ...
                'sarta_apr08_m140_wcon_nte'];
model = 'era';

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

addpath('/home/sbuczko1/git/swutils');
[sID, sTempPath] = genscratchpath();
trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);


% Read the AIRS2CCF file
fprintf(1, '>>> Reading input file: %s   ', inpath);

[eq_x_tai, freq, prof, pattr] = v6_readl2cc(inpath);

fprintf(1, 'Done\n');

head = struct;
head.pfields = 4;  % robs1, no calcs in file
head.ptype = 0;    
head.ngas = 0;

% Assign header attribute strings
hattr={ {'header' 'pltfid' 'Aqua'}, ...
        {'header' 'instid' 'AIRS'}, ...
        {'header' 'githash' trace.githash}, ...
        {'header' 'rundate' trace.RunDate}, ...
        {'header' 'klayers_exec' klayers_exec}, ...
        {'header' 'sarta_exec' sarta_exec} };

nchan = size(prof.robs1,1);
chani = (1:nchan)';
vchan = freq;

% Assign header variables
head.instid = 800; % AIRS 
head.pltfid = -9999;
head.nchan = length(chani);
head.ichan = chani;
head.vchan = vchan(chani);
head.vcmax = max(head.vchan);
head.vcmin = min(head.vchan);

% Assign profile attribute strings
% $$$ pattr={ {'' '' ''} };

% profile attribute changes for airibrad
% $$$ pattr = set_attr('profiles', 'robs1', infile);
% $$$ pattr = set_attr(pattr, 'rtime', 'TAI:1958');

% Fix for zobs altitude units
if isfield(prof,'zobs')
   iz = prof.zobs < 20000 & prof.zobs > 20;
   prof.zobs(iz) = prof.zobs(iz) * 1000;
end

% Add in model data
fprintf(1, '>>> Add model: %s...', model)
switch model
  case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
  case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
end
head.pfields = 5;
fprintf(1, 'Done\n');

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

% run klayers
fprintf(1, '>>> running klayers... ');
fn_rtp1 = fullfile(sTempPath, ['airs_' sID '_1.rtp']);
rtpwrite(fn_rtp1, head, hattr, prof, pattr);
fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               sTempPath '/kout.txt'];
unix(klayers_run);
fprintf(1, 'Done\n');

% Run sarta
fprintf(1, '>>> Running sarta... ');
fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
               ' > ' sTempPath '/sartaout.txt'];
unix(sarta_run);
hattr{end+1} = {'header' 'sarta' sarta_exec};
fprintf(1, 'Done\n');

% read in post-sarta results
[h,ha,p,pa] = rtpread(fn_rtp3);

% restore pre-klayers prof and insert sarta calcs
[head, hattr, prof, pattr] = rtpread(fn_rtp1);
prof.rcalc = p.rcalc;


fprintf(1, 'Done\n');

            
