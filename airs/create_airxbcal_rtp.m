%function create_airxbcal_rtp(doy, year)
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
doy = 100; year = 2013;
%---------------- Paths --------------
addpath /asl/matlib/h4tools
addpath /asl/matlib/rtptools
addpath /asl/matlib/science

% Path to new rtp_prod software
custom_path = '/strow/Git/rtp_prod2';

% Fix custom path to work on Mac and Linux
switch computer
  case 'MACI64'
    custom_path = fullfile('/Users/',custom_path);
  case 'GLNXA64'
    custom_path = fullfile('/home/',custom_path);
end

% Only need rtp_prod2/(airs,grib)
addpath(fullfile(custom_path,'airs'))
addpath(fullfile(custom_path,'grib'))

% Location of AIRXBCAL year directories
dn = '/asl/data/airs/AIRXBCAL';
ystr = sprintf('%d', year);
dstr = sprintf('%0.3d', doy);

indir = fullfile(dn, ystr, dstr);
fn = dir(fullfile(indir, '*.hdf'));
if length(fn) ~= 1
   disp('Note: Two files present, incorrect!');
end
fnfull = fullfile(indir,fn.name);

%---------------- Main --------------
% Read the AIRXBCAL file
[prof, pattr, aux] = read_airxbcal(fnfull);

% Header 
head = struct;
head.pfields = 4;  % robs1 only in file
head.ptype = 0;    
head.ngas = 0;

% Assign RTP attribute strings
hattr={ {'header' 'pltfid' 'Aqua'}, ...
        {'header' 'instid' 'AIRS'} };
pattr = set_attr(pattr,'rtime','seconds since 1 Jan 1993','profiles');

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

%hattr = set_attr(hattr,'rtpfile',[rtp_outfile]);

%[head prof] = subset_rtp(head, gdata, [], [], find(ifov));

% fix for zobs altitude
if isfield(prof,'zobs')
   iz = prof.zobs < 20000 & prof.zobs > 20;
   prof.zobs(iz) = prof.zobs(iz) * 1000;
end

% Save file w/o model data?
% rtpwrite(xxx,head,hattr,prof,pattr)

% Add in model data
[prof,head]=fill_era(prof,head);
head.pfields = 5;

% Don't use Sergio's SST fix for now
%[head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);
% Don't need topography for AIRS, built-in
% [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

% Dan Zhou's one-year climatology for land surface emissivity
% This routine also adds in sea surface emissivity
[head,hattr,prof,pattr]=rtpadd_emis_DanZhou(head,hattr,prof,pattr);

% Save the rtp file
rtpwrite('/home/strow/test1.rtp',head,hattr,prof,pattr)

% Klayers
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
klayers_run = [klayers_exec ' fin=test1.rtp fout=test2.rtp > /asl/s1/strow/kout.txt'];
unix(klayers_run);

% Sarta, pick depending on date
% /asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_preNov2003_wcon_nte
sarta_exec = '/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_postNov2003_wcon_nte'
sarta_run = [sarta_exec ' fin=test2.rtp fout=finalfile.rtp'];
unix(sarta_run);

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