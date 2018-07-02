function [head, hattr, prof, pattr] = create_airixcal_rtp(fnAirsInput, cfg)
%
% NAME
%   create_airixcal_rtp -- wrapper to process AIRIXCAL to RTP
%
% SYNOPSIS
%   create_airixcal_rtp(fnAirsInputopt)
%
% INPUTS
%   opt   - OPTIONAL struct containing misc information

%
% REQUIRES:
%      /asl/packages/rtp_prod2/airs, util, grib, emis
%      /asl/packages/swutil
func_name = 'create_airixcal_rtp';

addpath('/home/sbuczko1/git/rtp_prod2/airs/readers');
addpath('/home/sbuczko1/git/rtp_prod2/airs/calflag');
addpath('/home/sbuczko1/git/rtp_prod2/airs/util');

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';

trace.klayers = klayers_exec;
trace.sarta = sarta_exec;
trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

% Read the AIRIXCAL file
fprintf(1, '>>> Reading input file: %s   ', fnAirsInput);
[prof, pattr, aux] = read_airixcal(fnAirsInput);
fprintf(1, 'Done\n');

% subset by 20 during debugging
if isfield(cfg, 'DEBUG') & cfg.DEBUG == true
    fprintf(2, '>>> SUBSETTING FOR DEBUG\n');
    % subset data 95% for faster debugging/testing runs
    prof = rtp_sub_prof(prof,1:20:length(prof.rlat));
end

% Header 
head = struct;
head.pfields = 4;  % robs1, no calcs in file
head.ptype = 0;    
head.ngas = 0;

% Assign header attribute strings
hattr={ {'header' 'pltfid' 'Aqua'}, ...
        {'header' 'instid' 'AIRS'}, ...
        {'header' 'githash' trace.githash}, ...
        {'header' 'rundate' trace.RunDate} };

nchan = size(prof.robs1,1);
chani = (1:nchan)';
vchan = aux.nominal_freq(:);

% Assign header variables
head.instid = 800; % AIRS 
head.pltfid = -9999;
head.nchan = length(chani);
head.ichan = chani;
head.vchan = vchan(chani);
head.vcmax = max(head.vchan);
head.vcmin = min(head.vchan);

% Fix for zobs altitude units
if isfield(prof,'zobs')
   iz = prof.zobs < 20000 & prof.zobs > 20;
   prof.zobs(iz) = prof.zobs(iz) * 1000;
end


% $$$ nobs = length(prof.robs1);
% $$$ for iobsidx = [1:1000:nobs]
% $$$     iobsblock = [iobsidx:min(iobsidx+999,nobs)];
% $$$     [prof.calflag(:, iobsblock) cstr] = data_to_calnum_l1bcm( ...
% $$$         aux.nominal_freq, aux.NeN, aux.CalChanSummary, ...
% $$$         matchedcalflag(:,  iobsblock), ...
% $$$         prof.rtime(:, iobsblock), prof.findex(:, iobsblock));
% $$$ end
% $$$ clear aux matchedcalflag;  % reclaiming some memory
% $$$ fprintf(1, 'Done\n');

% Add in model data
fprintf(1, '>>> Add model: %s...', cfg.model)
switch cfg.model
  case 'ecmwf'
    which fill_ecmwf
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
  case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
end
head.pfields = 5;
fprintf(1, 'Done\n');

% Don't use Sergio's SST fix for now
% $$$ [head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);

% Don't need topography for AIRS, built-in
% $$$ [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_add_emis...');
[prof,pattr] = rtp_add_emis(prof,pattr);
fprintf(1, 'Done\n');

% Save the rtp file
fprintf(1, '>>> Saving first rtp file... ');
[sID, sTempPath] = genscratchpath();

fn_rtp1 = fullfile(sTempPath, ['airs_' sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr)
fprintf(1, 'Done\n');

% run klayers
fprintf(1, '>>> running klayers... ');
fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               sTempPath '/kout.txt'];
unix(klayers_run);
hattr{end+1} = {'header' 'klayers' klayers_exec};
fprintf(1, 'Done\n');

% Run sarta
% *** split fn_rtp3 into 'N' multiple chunks (via rtp_sub_prof like
% below for clear,site,etc?) make call to external shell script to
% run 'N' copies of sarta backgrounded
fprintf(1, '>>> Running sarta... ');
fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
               ' > ' sTempPath '/sartaout.txt'];
unix(sarta_run);
fprintf(1, 'Done\n');

% Read in new rcalcs and insert into origin prof field
stFileInfo = dir(fn_rtp3);
fprintf(1, ['*************\n>>> Reading fn_rtp3:\n\tName:\t%s\n\tSize ' ...
            '(GB):\t%f\n*************\n'], stFileInfo.name, stFileInfo.bytes/1.0e9);
[h,ha,p,pa] = rtpread(fn_rtp3);
prof.rcalc = p.rcalc;
head.pfields = 7;
hattr{end+1} = {'header' 'sarta' sarta_exec};

% temporary files are no longer needed. delete them to make sure we
% don't fill up the scratch drive.
delete(fn_rtp1, fn_rtp2, fn_rtp3);

fprintf(1, 'Done\n');


            