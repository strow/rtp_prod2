function [head, hattr, prof, pattr] = create_cris_ccast_hires_clear_gran_rtp(fnCrisInput, cfg)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS .mat granule file.

fprintf(1, '>> Running create_cris_ccast_hires_rtp for input: %s\n', ...
        fnCrisInput);


% read in configuration options from 'cfg'
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
if isfield(cfg, 'klayers_exec')
    klayers_exec = cfg.klayers_exec;
end

sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
               'sarta_iasi_may09_wcon_nte'];
if isfield(cfg, 'sarta_exec')
    sarta_exec = cfg.sarta_exec;
    USE_IASI_SARTA = false;  % this really needs to be a TEST of
                             % the configured sarta or needs to be
                             % set by an additional flag in cfg
end
nguard = 2;  % number of guard channels
if isfield(cfg, 'nguard')
    nguard = cfg.nguard;
end
nsarta = 4;  % number of sarta guard channels
if isfield(cfg, 'nsarta')
    nsarta = cfg.nsarta;
end
% check for validity of guard channel specifications
if nguard > nsarta
    fprintf(2, ['*** Too many guard channels requested/specified ' ...
                '(nguard/nsarta = %d/%d)***\n'], nguard, nsarta);
    return
end


addpath(genpath('/asl/matlib'));
% Need these two paths to use iasi2cris.m in iasi_decon
addpath /asl/packages/iasi_decon
addpath /asl/packages/ccast/source
addpath /asl/packages/rtp_prod2/cris;  % uniform_clear_template_...
addpath /asl/packages/ccast/motmsc/rtp_sarta; % ccast2rtp, cris_[iv]chan
addpath /asl/packages/rtp_prod2/grib;  % fill_era/ecmwf
addpath /asl/packages/rtp_prod2/emis;  % add_emis
addpath /asl/packages/rtp_prod2/util;  % rtpread/write

[sID, sTempPath] = genscratchpath();

% Load up rtp
[head, hattr, prof, pattr] = ccast2rtp(fnCrisInput, nguard, nsarta);
%%** second parameter sets up the use of 4 CrIS guard
%%channels. Looking at head.ichan and head.vchan shows some
%%similarity to the cris channel description in
%%https://hyperearth.wordpress.com/2013/07/09/cris-rtp-formats/, at
%%least for the first set of guard channels

% check that [iv]chan are column vectors
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


% Add profile data
switch cfg.model
  case 'ecmwf'
    [prof,head,pattr]=fill_ecmwf(prof,head,pattr);
  case 'era'
    [prof,head,pattr]=fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]=fill_merra(prof,head,pattr);    
end

% rtp now has profile and obs data ==> 5
head.pfields = 5;
[nchan,nobs] = size(prof.robs1);
head.nchan = nchan;
head.ngas=2;


% Add landfrac, etc.
[head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

% Add Dan Zhou's emissivity and Masuda emis over ocean
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_ad_emis...');
[prof,pattr] = rtp_add_emis_single(prof,pattr);
fprintf(1, 'Done\n');

% run Sergio's subsetting routine
fprintf(1, '>> Building basic filtering flags (uniform_clear_template...)\n');
% $$$ % $$$ px = rmfield(prof,'rcalc');
% $$$ hx = head; hx.pfields = 5;
fprintf(1, '>>> NGAS = %d\n', head.ngas);
px = uniform_clear_template_lowANDhires_HP(head,hattr,prof,pattr); %% super (if it works)

% subset out the clear
% output rtp splitting from airxbcal processing
% Subset into four types and save separately
iclear = find(px.iudef(1,:) == 1);
prof = rtp_sub_prof(px,iclear);
clear px;

% run klayers
fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr);
fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
unix([klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath '/klayers_stdout'])

% run sarta

% if using IASI sarta
if USE_IASI_SARTA
% $$$     % read in output from klayers and prep to run through IASI sarta
% $$$     [head, hattr, prof, pattr] = rtpread(fn_rtp2);
% $$$     
% $$$     % Remove CrIS channel dependent fields before doing IASI calc
% $$$     if (isfield(head,'vchan'))
% $$$         %%** removes the user space frequency channel array but leaves
% $$$         %%the channel index array (which sarta needs?)
% $$$         head = rmfield(head,'vchan');
% $$$     end
% $$$     if (isfield(prof,'robs1'))
% $$$         prof = rmfield(prof,'robs1');
% $$$         head.pfields = head.pfields - 4;
% $$$     end
% $$$     if (isfield(prof,'rcalc'))
% $$$         prof = rmfield(prof,'rcalc');
% $$$         head.pfields = head.pfields - 2;
% $$$     end
% $$$     if (isfield(prof,'calflag'))
% $$$         prof = rmfield(prof,'calflag');
% $$$     end
% $$$ 
% $$$     %%** fiasi is a LUT for the IASI frequency space channel
% $$$     %%allocations
% $$$     ltemp = load('/asl/data/iremis/danz/iasi_f', 'fiasi'); % load fiasi
% $$$     fiasi = ltemp.fiasi;
% $$$     clear ltemp;
% $$$ 
% $$$     % First half of IASI
% $$$     %%** replace both cris ichan and vchan with iasi equivalents (??
% $$$     %%but without guard channels??). This is done because we have a
% $$$     %%sarta model for iasi but not for cris, correct?? Why, exactly did
% $$$     %%we do the field removal of head.vchan a few lines ago but not
% $$$     %%similarly remove ichan? Here, we replace both with iasi
% $$$     %%equiv. so, why the removal?
% $$$     head.nchan = 4231;
% $$$     head.ichan = (1:4231)';
% $$$     head.vchan = fiasi(1:4231);
% $$$     fn_rtpi = fullfile(sTempPath, ['cris_' sID '_rtpi.rtp']);
% $$$     rtpwrite(fn_rtpi,head,hattr,prof,pattr);
% $$$     fn_rtprad = fullfile(sTempPath, ['cris_' sID '_rtprad.rtp']);
% $$$     disp('running SARTA for IASI channels 1-4231')
% $$$     eval(['! ' sarta_exec ' fin=' fn_rtpi ' fout=' fn_rtprad ' > ' ...
% $$$           sTempPath '/sartastdout1.txt']);
% $$$     %psarta_run(fn_rtpi, fn_rtprad, sarta_exec);
% $$$     [head, hattr, prof, pattr] = rtpread(fn_rtprad);
% $$$     rad_pt1 = prof.rcalc;
% $$$     % Second half of IASI
% $$$     head.nchan = 4230;
% $$$     head.ichan = (4232:8461)';
% $$$     head.vchan = fiasi(4232:8461);
% $$$     rtpwrite(fn_rtpi,head,hattr,prof,pattr);
% $$$     disp('running SARTA for IASI channels 4232-8461')
% $$$     eval(['! ' sarta_exec ' fin=' fn_rtpi ' fout=' fn_rtprad ' > ' ...
% $$$           sTempPath '/sartastdout2.txt' ]);
% $$$     %psarta_run(fn_rtpi, fn_rtprad, sarta_exec);
% $$$     [head, hattr, prof, pattr] = rtpread(fn_rtprad);
% $$$     rad_pt2 = prof.rcalc;
% $$$ 
% $$$     %
% $$$     rad_iasi = [rad_pt1; rad_pt2];
% $$$     clear rad_pt1 rad_pt2
% $$$ 
% $$$     % Convert IASI radiances to CrIS
% $$$     opt.hapod = 0;  % Want sinc from iasi2cris
% $$$     opt.resmode = 'hires2'; % CrIS mode after Dec. 4, 2014
% $$$     opt.nguard = nguard; % adding 2 guard channels
% $$$ 
% $$$     % Convert Iasi to CrIS
% $$$     [tmp_rad_cris, f_cris] = iasi2cris(rad_iasi,fiasi,opt);
% $$$     %%% trying to add 2 guard channels. This check will need to be
% $$$     %%% redone but, for now, I will just remove it
% $$$ % $$$ % f_cris are real channels, no guard channels
% $$$     [num_ichan_iasi, num_profs] = size(tmp_rad_cris);
% $$$ % $$$ if num_ichan_iasi ~= 2211
% $$$ % $$$    disp('Error: iasi2cris returning wrong channels');
% $$$ % $$$ end
% $$$ 
% $$$     % Full g4 radiance variable
% $$$     rad_cris = ones(length(ichan_ccast),num_profs).*NaN;
% $$$     % Indices (not channels) for real radiances
% $$$     ireal = find(ichan_ccast <= 2211);
% $$$ 
% $$$ % $$$ rad_cris(ireal,:) = tmp_rad_cris;
% $$$     rad_cris = tmp_rad_cris;
% $$$     % end if USE_IASI_SARTA true
else
    fprintf(1, '>>> Running sarta... ');
    fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
    sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
                 ' > ' sTempPath '/sartaout.txt'];
    unix(sarta_run);

    % read in sarta results to capture rcalc
    [~,~,p,~] = rtpread(fn_rtp3);
    prof.rclr = p.rcalc;
    clear p;
    fprintf(1, 'Done\n');
end  % end run sarta 
    
