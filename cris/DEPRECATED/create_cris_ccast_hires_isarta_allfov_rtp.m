function [head, hattr, prof, pattr] = create_cris_ccast_hires_isarta_allfov_rtp(fnCrisInput, cfg)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS hires .mat granule file.
funcname = 'create_cris_ccast_hires_isarta_allfov_rtp';

fprintf(1, '>> Running %s for input: %s\n', funcname, fnCrisInput);

addpath(genpath('/asl/matlib'));
% Need these two paths to use iasi2cris.m in iasi_decon
addpath /asl/packages/iasi_decon
addpath /asl/packages/ccast/source
addpath /asl/matlib/aslutil   % int2bits
addpath /home/sbuczko1/git/rtp_prod2_DEV/grib;  % fill_era/ecmwf
addpath /home/sbuczko1/git/rtp_prod2_DEV/emis;  % add_emis
addpath /home/sbuczko1/git/rtp_prod2_DEV/util;  % rtpread/write
addpath /home/sbuczko1/git/rtp_prod2_DEV/cris/readers % sdr read
                                                      % function

addpath /home/sbuczko1/git/rtp_prod2_DEV/cris/util  % build_satlat
addpath /home/sbuczko1/git/rtp_prod2_DEV/util  % genscratchpath
addpath /home/sbuczko1/git/rtp_prod2_DEV/util/time % time functions

[sID, sTempPath] = genscratchpath();

cfg.sID = sID;
cfg.sTempPath = sTempPath;

sartaclr_exec = cfg.sartaclr_exec;

% check for validity of guard channel specifications
nguard = cfg.nguard;
nsarta = cfg.nsarta;
if nguard > nsarta
    fprintf(2, ['*** Too many guard channels requested/specified ' ...
                '(nguard/nsarta = %d/%d)***\n'], nguard, nsarta);
    return
end

% Load up rtp
fprintf(1, '> Reading in granule file %s\n', fnCrisInput);
[head, hattr, prof, pattr] = ccast2rtp(fnCrisInput, nguard, nsarta);

% ccast granules do not seem to be reporting asc/desc flag properly
% so fill in by solzen
%prof.iudef(4,:) = (prof.solzen < 90.0);

% check ichan index order (to avoid problems with rtpwrite)
temp = size(head.ichan);
if temp(2) > 1
    head.ichan = head.ichan';
end
temp = size(head.vchan);
if temp(2) > 1
    head.vchan = head.vchan';
end

% Need this later
ichan_ccast = head.ichan;

% build sub satellite lat point
[prof, pattr] = build_satlat(prof,pattr);

% Add profile data
model = cfg.model;
fprintf(1, '>>> Add model: %s...', model)
switch model
  case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr,cfg);
  case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
end

% rtp now has profile and obs data ==> 5
head.pfields = 5;
[nchan,nobs] = size(prof.robs1);
head.nchan = nchan;
% $$$ head.ngas=2;
fprintf(1, 'Done\n');

% Add landfrac, etc.
fprintf(1, '>>> Running rtpadd_usgs_10dem...');
[head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);
fprintf(1, 'Done\n');

% Add Dan Zhou's emissivity and Masuda emis over ocean
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_add_emis_single...');
[prof,pattr] = rtp_add_emis_single(prof,pattr);
fprintf(1, 'Done\n');

% run klayers
fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
fprintf(1, '>>> Writing klayers input temp file %s ...', fn_rtp1);
rtpwrite(fn_rtp1,head,hattr,prof,pattr)
fprintf(1, 'Done\n')
fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
unix([cfg.klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath ...
      '/klayers_' sID '_stdout'])
fprintf(1, 'Done\n');

% Run sarta
fprintf(1, '>>> Running sarta... ');
% $$$ 
%*************************************************
[head, hattr, prof, pattr] = rtpread(fn_rtp2);    % Remove CrIS channel dependent fields before doing IASI calc
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
%%** fiasi is a LUT for the IASI frequency space channel
%%allocations
ltemp = load('/home/sbuczko1/git/rtp_prod2_DEV/cris/static/iasi_f', 'fiasi'); % load fiasi
fiasi = ltemp.fiasi;
clear ltemp;

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
eval(['! ' sartaclr_exec ' fin=' fn_rtpi ' fout=' fn_rtprad ' > sartastdout1.txt']);
%psarta_run(fn_rtp2, fn_rtprad, sarta_exec);
[head, hattr, prof, pattr] = rtpread(fn_rtprad);
rad_pt1 = prof.rcalc;
% Second half of IASI
head.nchan = 4230;
head.ichan = (4232:8461)';
head.vchan = fiasi(4232:8461);
disp('running SARTA for IASI channels 4232-8461')
eval(['! ' sartaclr_exec ' fin=' fn_rtpi ' fout=' fn_rtprad ' > sartastdout2.txt' ]);
%psarta_run(fn_rtpi, fn_rtprad, sarta_exec);
[head, hattr, prof, pattr] = rtpread(fn_rtprad);
rad_pt2 = prof.rcalc;

%
rad_iasi = [rad_pt1; rad_pt2];
clear rad_pt1 rad_pt2

% Convert IASI radiances to CrIS
opt.hapod = cfg.hapod;  % Want sinc from iasi2cris
opt.resmode = cfg.resmode; % CrIS mode after Dec. 4, 2014
opt.nguard = cfg.nguard; % adding 0 guard channels

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
% Make head reflect calcs
head.pfields = 7;  % robs, model, calcs


end  % end function




