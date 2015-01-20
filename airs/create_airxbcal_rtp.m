%function create_airxbcal_rtp(airs_doy, airs_year)
%
% NAME
%   create_airxbcal_rtp -- wrapper to process AIRXBCAL to RTP
%
% SYNOPSIS
%   create_airxbcal_rtp(doy, year)
%
% INPUTS
%   day   - integer day of year
%   year  - integer year
%
% L. Strow, Jan. 14, 2015
%
% DISCUSSION (TBD)
airs_doy = 239; airs_year = 2013;

% Convert to Matlab datetime format
mtime     = datetime(airs_year,1,1);
mtime.Day = airs_doy;

doystr = num2str(airs_doy);

yrstr = datestr(mtime,'yyyy');
monstr = datestr(mtime,'mm');
daystr = datestr(mtime,'dd');

%---------------- Paths --------------
addpath /asl/matlib/h4tools
addpath /asl/matlib/rtptools
addpath /asl/matlib/science

% Assume you are in rtp_prod2/airs/runs
addpath ../../grib
addpath ../../airs

% Location of AIRXBCAL year directories
dn = '/asl/data/airs/AIRXBCAL';

indir = fullfile(dn, ystr, doystr);
fn = dir(fullfile(indir, '*.hdf'));
if length(fn) ~= 1
   disp('Note: Two files present, incorrect!');
end
fnfull = fullfile(indir,fn.name);

% Read the AIRXBCAL file
[prof, pattr, aux] = read_airxbcal(fnfull);

% Header 
head = struct;
head.pfields = 4;  % robs1 only in file
head.ptype = 0;    
head.ngas = 0;

% Assign RTP header attribute strings
hattr={ {'header' 'pltfid' 'Aqua'}, ...
        {'header' 'instid' 'AIRS'} };

nchan = size(prof.robs1,1);
chani = (1:nchan)';
vchan = aux.nominal_freq(:);

% Assign head variables
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

% Add in model data
[prof,head]  = fill_era(prof,head);
head.pfields = 5;

% Don't use Sergio's SST fix for now
%[head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);
% Don't need topography for AIRS, built-in
% [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

% Dan Zhou's one-year climatology for land surface emissivity
% This routine also adds in sea surface emissivity
[head,hattr,prof,pattr]=rtpadd_emis_DanZhou(head,hattr,prof,pattr);

% Save the rtp file
fn_rtp1 = tempname;
rtpwrite(tempname,head,hattr,prof,pattr)

% Klayers
fn_rtp2 = tempname;
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > /asl/s1/strow/kout.txt'];
unix(klayers_run);

% Sarta, pick depending on date
% /asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_preNov2003_wcon_nte
fn_rtp3 = tempname;
sarta_exec = '/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_postNov2003_wcon_nte'
sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ];
%sarta_run = [sarta_exec ' fin=test2_ecmwf.rtp fout=finalfile_ecmwf.rtp'];
unix(sarta_run);

% Read in new rcalcs and insert into origin prof field
% Would it save much to just read in rcalc using hdf4 calls?
[h,ha,p,pa]=rtpread(fn_rtp3);

prof.rcalc = p.rcal;
head.pfields = 7;

rtp_outname = fullfile('/asl/data/rtprod_airs_test/',yrstr,monstr,daystr);
rtpwrite(final_rtp_file,head,hattr,prof,pattr);
% delete temporary files

%{
Code for getting calflag into rtp

for iobsidx = [1:1000:nobs]
   iobsblock = [iobsidx:min(iobsidx+999,nobs)];
   [prof.calflag(:,iobsblock) cstr] = data_to_calnum_l1bcm(...
      nominal_freq, NeN, CalChanSummary, ...
      calflag(:,iobsblock), prof.rtime(:,iobsblock), ...
      prof.findex(:,iobsblock));
end
%}

% dd = datetime(rtime,'ConvertFrom','epochtime','Epoch','1993-01-01');