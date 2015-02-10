function create_airxbcal_rtp(airs_doy, airs_year)
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

% addpath /asl/matlib/h4tools

%airs_doy = 239; airs_year = 2013;

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';

% Execute user-defined paths
set_process_dirs
addpath(genpath(rtp_sw_dir));

% Location of AIRXBCAL year directories
dn = '/asl/data/airs/AIRXBCAL';
% Strings needed for file names
airs_doystr  = sprintf('%03d',airs_doy);
airs_yearstr = sprintf('%4d',airs_year);

indir = fullfile(dn, airs_yearstr, airs_doystr);
fn = dir(fullfile(indir, '*.hdf'));
if length(fn) ~= 1
   disp('Note: Two files present, incorrect!');
end
fnfull = fullfile(indir,fn.name);

% Read the AIRXBCAL file
[prof, pattr, aux] = read_airxbcal(fnfull);

disp('done readling file')

% Header 
head = struct;
head.pfields = 4;  % robs1, no calcs in file
head.ptype = 0;    
head.ngas = 0;

% Assign header attribute strings
hattr={ {'header' 'pltfid' 'Aqua'}, ...
        {'header' 'instid' 'AIRS'} };

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

% subset by 20 during debugging
%prof = rtp_sub_prof(prof,1:20:length(prof.rlat));

% Add in Scott's calflag
matchedcalflag = mkmatchedcalflag(airs_year, airs_doy, prof);
[prof.calflag cstr] = data_to_calnum_l1bcm(...
          aux.nominal_freq, aux.NeN, ...
          aux.CalChanSummary, ...
          matchedcalflag', prof.rtime, prof.findex);

disp('done with calflag')

% Add in model data
[prof,head]  = fill_era(prof,head);
head.pfields = 5;

% Don't use Sergio's SST fix for now
% [head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);

% Don't need topography for AIRS, built-in
% [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
[prof,pattr] = rtp_add_emis(prof,pattr);

disp('done with add emis')

% Save the rtp file
fn_rtp1 = tempname;
fn_rtp1 = [fn_rtp1 '.rtp'];
rtpwrite(fn_rtp1,head,hattr,prof,pattr)

disp('saved first rtp file')

% run klayers
fn_rtp2 = tempname;
fn_rtp2 = [fn_rtp2 '.rtp'];
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > /asl/s1/strow/kout.txt'];
unix(klayers_run);

disp('done with klayers')

% Run sarta
fn_rtp3 = tempname;
fn_rtp3 = [fn_rtp3 '.rtp'];
sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ];
%sarta_run = [sarta_exec ' fin=test2_ecmwf.rtp fout=finalfile_ecmwf.rtp'];
unix(sarta_run);

disp('done with sarta')

% Read in new rcalcs and insert into origin prof field
[h,ha,p,pa] = rtpread(fn_rtp3);
prof.rcalc = p.rcalc;
head.pfields = 7;

% Subset into four types and save separately
iclear = find(bitget(prof.iudef(1,:),1));
isite  = find(bitget(prof.iudef(1,:),2));
idcc   = find(bitget(prof.iudef(1,:),3));
irand  = find(bitget(prof.iudef(1,:),4));

prof_clear = rtp_sub_prof(prof,iclear);
prof_site  = rtp_sub_prof(prof,isite);
prof_dcc   = rtp_sub_prof(prof,idcc);
prof_rand  = rtp_sub_prof(prof,irand);

% Make directory if needed
if exist(fullfile(airxbcal_out_dir,airs_yearstr)) == 0
   mkdir(airxbcal_out_dir,airs_yearstr);
end

rtp_out_fn_head = ['era_airxbcal_day' airs_doystr];
% Now save the four types of airxbcal files

rtp_out_fn = [rtp_out_fn_head, '_clear.rtp'];
rtp_outname = fullfile(airxbcal_out_dir,airs_yearstr,rtp_out_fn);
rtpwrite(rtp_outname,head,hattr,prof_clear,pattr);

rtp_out_fn = [rtp_out_fn_head, '_site.rtp'];
rtp_outname = fullfile(airxbcal_out_dir,airs_yearstr,rtp_out_fn);
rtpwrite(rtp_outname,head,hattr,prof_site,pattr);

rtp_out_fn = [rtp_out_fn_head, '_dcc.rtp'];
rtp_outname = fullfile(airxbcal_out_dir,airs_yearstr,rtp_out_fn);
rtpwrite(rtp_outname,head,hattr,prof_dcc,pattr);

rtp_out_fn = [rtp_out_fn_head, '_rand.rtp'];
rtp_outname = fullfile(airxbcal_out_dir,airs_yearstr,rtp_out_fn);
rtpwrite(rtp_outname,head,hattr,prof_rand,pattr);



            