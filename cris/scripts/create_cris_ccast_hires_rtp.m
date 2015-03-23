function create_cris_ccast_hires_rtp(fnCrisInput, fnCrisOutput)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS .mat granule file.

%set_process_dirs;

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte';

addpath(genpath('/asl/matlib'));
% Need these two paths to use iasi2cris.m in iasi_decon
addpath /asl/packages/iasi_decon
addpath /asl/packages/ccast/source

% Load up rtp 
[head, hattr, prof, pattr] = ccast2rtp(fnCrisInput, 4);
% Need this later
ichan_ccast = head.ichan;
% Add profile data
[prof,head]=fill_era(prof,head);
% rtp now has profile and obs data ==> 5
head.pfields = 5;
% Add landfrac, etc.
[head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);
% Add Dan Zhou's emissivity and Masuda emis over ocean
[prof,pattr] = rtp_add_emis(prof,pattr);
% Subset for quicker debugging
% prof = rtp_sub_prof(prof, 1:10:length(prof.rlat));
rtp1 = tempname;
rtpwrite(rtp1,head,hattr,prof,pattr)
rtp2 = tempname;

% run klayers
unix([klayers_exec ' fin=' rtp1 ' fout=' rtp2 ' > klayers_stdout'])
[head, hattr, prof, pattr] = rtpread(rtp2);

% Now run IASI SARTA 
% Remove CrIS channel dependent fields before doing IASI calc
if (isfield(head,'vchan'))
  head = rmfield(head,'vchan');
end
if (isfield(prof,'robs1'))
  prof = rmfield(prof,'robs1');
  head.pfields = head.pfields - 4;
end
if (isfield(prof,'rcalc'))
  prof = rmfield(prof,'rcalc');
  head.pfields = head.pfields - 2;
end
if (isfield(prof,'calflag'))
  prof = rmfield(prof,'calflag');
end
% Run IASI SARTA
load /asl/data/iremis/danz/iasi_f  % load fiasi
% First half of IASI
head.nchan = 4231;
head.ichan = (1:4231)';
head.vchan = fiasi(1:4231);
rtpi = tempname;
rtpwrite(rtpi,head,hattr,prof,pattr);
rtprad = tempname;
disp('running SARTA for IASI channels 1-4231')
eval(['! ' sarta_exec ' fin=' rtpi ' fout=' rtprad ' > sartastdout1.txt']);
[head, hattr, prof, pattr] = rtpread(rtprad);
rad_pt1 = prof.rcalc;
% Second half of IASI
head.nchan = 4230;
head.ichan = (4232:8461)';
head.vchan = fiasi(4232:8461);
rtpwrite(rtpi,head,hattr,prof,pattr);
disp('running SARTA for IASI channels 4232-8461')
eval(['! ' sarta_exec ' fin=' rtpi ' fout=' rtprad ' > sartastdout2.txt' ]);
[head, hattr, prof, pattr] = rtpread(rtprad);
rad_pt2 = prof.rcalc;
%
rad_iasi = [rad_pt1; rad_pt2];
clear rad_pt1 rad_pt2

% Convert IASI radiances to CrIS
opt.hapod = 0;  % Want sinc from iasi2cris
opt.resmode = 'hires2'; % CrIS mode after Dec. 4, 2014
% Convert Iasi to CrIS
[tmp_rad_cris, f_cris] = iasi2cris(rad_iasi,fiasi,opt);
% f_cris are real channels, no guard channels
[num_ichan_iasi, num_profs] = size(tmp_rad_cris);
if num_ichan_iasi ~= 2211
   disp('Error: iasi2cris returning wrong channels');
end
% Full g4 radiance variable
rad_cris = ones(length(ichan_ccast),num_profs).*NaN;
% Indices (not channels) for real radiances
ireal = find(ichan_ccast <= 2211);
rad_cris(ireal,:) = tmp_rad_cris;
% Go get output from klayers, which is what we want except for rcalc
[head, hattr, prof, pattr] = rtpread(rtp2);
% Insert rcalc for CrIS derived from IASI SARTA
prof.rcalc = real(rad_cris);
% Final rtp file
rtpwrite(fnCrisOutput', head, hattr, prof, pattr)
% Next delete temporary files
delete(rtp1);delete(rtp2);delete(rtpi);delete(rtprad);
