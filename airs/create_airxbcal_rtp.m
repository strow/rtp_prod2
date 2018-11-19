function [head, hattr, prof, pattr] = create_airxbcal_rtp(inpath, cfg)
%
% NAME
%   create_airxbcal_rtp -- wrapper to process AIRXBCAL to RTP
%
% SYNOPSIS
%   create_airxbcal_rtp(doy, year, opt)
%
% INPUTS
%   day   - integer day of year
%   year  - integer year
%   opt   - OPTIONAL struct containing misc information
% L. Strow, Jan. 14, 2015
%
% REQUIRES:
%      /asl/packages/rtp_prod2_PROD/airs, util, grib, emis
%      /asl/packages/swutil
func_name = 'create_airxbcal_rtp';

addpath('/home/sbuczko1/git/rtp_prod2_DEV/airs/readers');
addpath('/home/sbuczko1/git/rtp_prod2_DEV/airs/calflag');
addpath('/home/sbuczko1/git/rtp_prod2_DEV/airs/util');

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';

trace.klayers = klayers_exec;
trace.sarta = sarta_exec;
trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

% YEAR and DOY are in the retrieved filename. Parse this and
% pull them out
C = strsplit(inpath, '/');
iYear = str2num(C{6});
iDoy = str2num(C{7});  
airs_yearstr = sprintf('%4d', iYear);
airs_doystr = sprintf('%03d', iDoy);

fn = dir(fullfile(inpath, '*.hdf'));
if (length(fn) > 1)
    fprintf(1, ['>>> *** More than one input ARIXBCAL hdf file present. Terminating ' ...
                'processing ***\n']);
    return;
elseif (length(fn) == 0)
    fprintf(1, ['>>> *** No input AIRXBCAL hdf file available. Terminating ' ...
                'processing ***\n']);
    return;
end

airxbcal_out_dir = cfg.outfile_head;

fnfull = fullfile(inpath,fn.name);

% Read the AIRXBCAL file
fprintf(1, '>>> Reading input file: %s   ', fnfull);
[prof, pattr, aux] = read_airxbcal(fnfull);
fprintf(1, 'Done\n');

% subset for the DCCs to speed up processing
idcc   = find(bitget(prof.iudef(1,:),3));
prof   = rtp_sub_prof(prof,idcc);

% subset by 20 during debugging
bDEBUG=0;
if bDEBUG
    fprintf(2, '>>> SUBSETTING FOR DEBUG\n');
    % subset data 95% for faster debugging/testing runs
    prof = rtp_sub_prof(prof,1:20:length(prof.rlat));
end

% subset if nobs is greater than threshold lmax (to avoid hdf file size
% limitations and hdfvs() failures during rtp write/read
% later). Keeps dcc, site and random obs intact and reduces number
% of clear obs to meet threshold limit
lmax = 72000;
fprintf(1, '>>> *** %d pre-subset obs ***\n', length(prof.rtime));
if length(prof.rtime) > lmax
    fprintf(1, '>>>*** nobs > %d. subsetting clear... ', lmax);
    prof = sub_airxbcal(prof, lmax);
    fprintf(1, 'Done ***\n');
    fprintf(1, '>>> *** %d subset obs ***\n', length(prof.rtime));
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

% Add in Scott's calflag
fprintf(1, '>>> Matching calflags... ');
[status, tmatchedcalflag] = mkmatchedcalflag(iYear, iDoy, ...
                                            prof);
if status == 99
    fprintf(1, ['>>> *** Corrupt meta data file. Terminating ' ...
                'processing\n']); 
    return;
elseif status == 98
    fprintf(1, ['>>> *** Calflag meta data file missing. Terminating ' ...
                'processing\n']);
    return;
end

matchedcalflag = transpose(tmatchedcalflag);
clear tmatchedcalflag;

nobs = length(prof.robs1);
for iobsidx = [1:1000:nobs]
    iobsblock = [iobsidx:min(iobsidx+999,nobs)];
    [prof.calflag(:, iobsblock) cstr] = data_to_calnum_l1bcm( ...
        aux.nominal_freq, aux.NeN, aux.CalChanSummary, ...
        matchedcalflag(:,  iobsblock), ...
        prof.rtime(:, iobsblock), prof.findex(:, iobsblock));
end
clear aux matchedcalflag;  % reclaiming some memory
fprintf(1, 'Done\n');

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
% [head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);

% Don't need topography for AIRS, built-in
% [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

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

% $$$ tic;
% $$$ psarta_run(fn_rtp2, fn_rtp3, sarta_exec);
% $$$ toc;
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

% Subset into four types and save separately
% $$$ iclear = find(bitget(prof.iudef(1,:),1));
% $$$ isite  = find(bitget(prof.iudef(1,:),2));

% $$$ irand  = find(bitget(prof.iudef(1,:),4));

% $$$ prof_clear = rtp_sub_prof(prof,iclear);
% $$$ prof_site  = rtp_sub_prof(prof,isite);
% $$$ prof_rand  = rtp_sub_prof(prof,irand);

% Make directory if needed
asType = {'dcc'};
for i = 1:length(asType)
    sPath = fullfile(airxbcal_out_dir,airs_yearstr,char(asType(i)));
    if exist(sPath) == 0
        mkdir(sPath);
    end
end

rtp_out_fn_head = ['era_airxbcal_day' airs_doystr];
% $$$ rtp_out_fn_head = ['new_era_airxbcal_day' airs_doystr];
% Now save the four types of airxbcal files
fprintf(1, '>>> writing output rtp files... ');

% $$$ if length(iclear)
% $$$     rtp_out_fn = [rtp_out_fn_head, '_clear.rtp'];
% $$$     rtp_outname = fullfile(airxbcal_out_dir,airs_yearstr, char(asType(1)), rtp_out_fn);
% $$$     rtpwrite(rtp_outname,head,hattr,prof_clear,pattr);
% $$$ else
% $$$     fprintf(2, '>> AIRS year %c  day %c has no clear obs\n', airs_yearstr, ...
% $$$             airs_doystr);
% $$$ end
% $$$ 
% $$$ 
% $$$ if length(isite)
% $$$     rtp_out_fn = [rtp_out_fn_head, '_site.rtp'];
% $$$     rtp_outname = fullfile(airxbcal_out_dir,airs_yearstr, char(asType(2)), rtp_out_fn);
% $$$     rtpwrite(rtp_outname,head,hattr,prof_site,pattr);
% $$$ else
% $$$     fprintf(2, '>> AIRS year %c  day %c has no site obs\n', airs_yearstr, ...
% $$$             airs_doystr);
% $$$ end

if length(idcc)
    rtp_out_fn = [rtp_out_fn_head, '_dcc.rtp'];
    rtp_outname = fullfile(airxbcal_out_dir,airs_yearstr, char(asType(1)), rtp_out_fn);
    rtpwrite(rtp_outname,head,hattr,prof,pattr);
else
    fprintf(2, '>> AIRS year %c  day %c has no dcc obs\n', airs_yearstr, ...
            airs_doystr);
end

% $$$ rtp_out_fn = [rtp_out_fn_head, '_rand.rtp'];
% $$$ rtp_outname = fullfile(airxbcal_out_dir,airs_yearstr, char(asType(4)), rtp_out_fn);
% $$$ rtpwrite(rtp_outname,head,hattr,prof_rand,pattr);
fprintf(1, 'Done\n');


            