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

[sID, sTempPath] = genscratchpath();

nguard = 2;  % number of guard channels

% Load up rtp 
[head, hattr, prof, pattr] = ccast2rtp(fnCrisInput, nguard);
%%** second parameter sets up the use of 4 CrIS guard
%%channels. Looking at head.ichan and head.vchan shows some
%%similarity to the cris channel description in
%%https://hyperearth.wordpress.com/2013/07/09/cris-rtp-formats/, at
%%least for the first set of guard channels

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% REMOVE THIS BEFORE PRODUCTION COMMIT     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% subset rtp for faster debugging
%%%% JUST GRAB THE FIRST 100 OBS
% $$$ fprintf(1, '>>> SUBSETTING PROF FOR DEBUG\n');
% $$$ iTest =(1:100);
% $$$ prof_sub = prof;
% $$$ prof = rtp_sub_prof(prof_sub, iTest);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Need this later
ichan_ccast = head.ichan;
% Add profile data
% $$$ [prof,head]=fill_era(prof,head);
[prof,head]=fill_ecmwf(prof,head);
% rtp now has profile and obs data ==> 5
head.pfields = 5;
% Add landfrac, etc.
[head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);
% Add Dan Zhou's emissivity and Masuda emis over ocean
[prof,pattr] = rtp_add_emis_single(prof,pattr);
% Subset for quicker debugging
% prof = rtp_sub_prof(prof, 1:10:length(prof.rlat));
fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr)
fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);

% run klayers
unix([klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath '/klayers_stdout'])
[head, hattr, prof, pattr] = rtpread(fn_rtp2);

% Now run IASI SARTA 
% Remove CrIS channel dependent fields before doing IASI calc
if (isfield(head,'vchan'))
    %%** removes the user space frequency channel array but leaves
    %%the channel index array (which sarta needs?)
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
%%** fiasi is a LUT for the IASI frequency space channel
%%allocations

% First half of IASI
%%** replace both cris ichan and vchan with iasi equivalents (??
%%but without guard channels??). This is done because we have a
%%sarta model for iasi but not for cris, correct?? Why, exactly did
%%we do the field removal of head.vchan a few lines ago but not
%%similarly remove ichan? Here, we replace both with iasi
%%equiv. so, why the removal?
head.nchan = 4231;
head.ichan = (1:4231)';
head.vchan = fiasi(1:4231);
fn_rtpi = fullfile(sTempPath, ['cris_' sID '_rtpi.rtp']);
rtpwrite(fn_rtpi,head,hattr,prof,pattr);
fn_rtprad = fullfile(sTempPath, ['cris_' sID '_rtprad.rtp']);
disp('running SARTA for IASI channels 1-4231')
eval(['! ' sarta_exec ' fin=' fn_rtpi ' fout=' fn_rtprad ' > sartastdout1.txt']);
%psarta_run(fn_rtpi, fn_rtprad, sarta_exec);
[head, hattr, prof, pattr] = rtpread(fn_rtprad);
rad_pt1 = prof.rcalc;
% Second half of IASI
head.nchan = 4230;
head.ichan = (4232:8461)';
head.vchan = fiasi(4232:8461);
rtpwrite(fn_rtpi,head,hattr,prof,pattr);
disp('running SARTA for IASI channels 4232-8461')
eval(['! ' sarta_exec ' fin=' fn_rtpi ' fout=' fn_rtprad ' > sartastdout2.txt' ]);
%psarta_run(fn_rtpi, fn_rtprad, sarta_exec);
[head, hattr, prof, pattr] = rtpread(fn_rtprad);
rad_pt2 = prof.rcalc;

%
rad_iasi = [rad_pt1; rad_pt2];
clear rad_pt1 rad_pt2

% Convert IASI radiances to CrIS
opt.hapod = 0;  % Want sinc from iasi2cris
opt.resmode = 'hires2'; % CrIS mode after Dec. 4, 2014
opt.nguard = nguard; % adding 2 guard channels
% Convert Iasi to CrIS
[tmp_rad_cris, f_cris] = iasi2cris(rad_iasi,fiasi,opt);
%%% trying to add 2 guard channels. This check will need to be
%%% redone but, for now, I will just remove it
% $$$ % f_cris are real channels, no guard channels
[num_ichan_iasi, num_profs] = size(tmp_rad_cris);
% $$$ if num_ichan_iasi ~= 2211
% $$$    disp('Error: iasi2cris returning wrong channels');
% $$$ end

% Full g4 radiance variable
rad_cris = ones(length(ichan_ccast),num_profs).*NaN;
% Indices (not channels) for real radiances
ireal = find(ichan_ccast <= 2211);

% $$$ rad_cris(ireal,:) = tmp_rad_cris;
rad_cris = tmp_rad_cris;
% Go get output from klayers, which is what we want except for rcalc
[head, hattr, prof, pattr] = rtpread(fn_rtp2);
% Insert rcalc for CrIS derived from IASI SARTA
prof.rcalc = real(rad_cris);
% Final rtp file
rtpwrite(fnCrisOutput, head, hattr, prof, pattr)
% Next delete temporary files
delete(fn_rtp1);delete(fn_rtp2);delete(fn_rtpi);delete(fn_rtprad);
