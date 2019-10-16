function create_cris_ccast_lowres_iasi_rtp(fnCrisInput)
% PROCESS_CRIS_LOWRES process one granule of CrIS data
%
% Process a single CrIS .mat granule file.

%set_process_dirs;

fprintf(1, '>> Running create_cris_ccast_lowres_rtp for input: %s\n', ...
        fnCrisInput);

% use fnCrisOutput to generate year and doy strings
% fnCrisOutput will be of the form rtp_d<YYYMMDD>_t<granule time>
[path, name, ext] = fileparts(fnCrisInput);
fnCrisOutput = name(4:end);
cris_yearstr = name(6:9);
month = str2num(name(10:11));
day = str2num(name(12:13));
dt = datetime(str2num(cris_yearstr), month, day);
dt.Format = 'DDD';
cris_doystr = char(dt);

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
               'sarta_iasi_may09_wcon_nte'];
% $$$ sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
% $$$                'sarta_crisg4_nov09_wcon_nte'];  %% lowres

addpath /home/sbuczko1/git/rtp_prod2/cris/readers  % ccast2rtp
addpath(genpath('/asl/matlib'));
% Need these two paths to use iasi2cris.m in iasi_decon
addpath /asl/packages/iasi_decon
addpath /asl/packages/ccast/source
addpath /asl/packages/rtp_prod2/cris
addpath /asl/packages/rtp_prod2/util
addpath /asl/packages/rtp_prod2/emis
addpath /asl/packages/rtp_prod2/grib

[sID, sTempPath] = genscratchpath();
sID = getenv('SLURM_ARRAY_TASK_ID');
nguard = 2;  % number of guard channels

% Load up rtp
try
    [head, hattr, prof, pattr] = ccast2rtp(fnCrisInput, nguard);
catch
    fprintf(2, '>>> ERROR: ccast2rtp failed for %s\n', ...
            fnCrisInput);
    return;
end

temp = size(head.ichan)
if temp(2) > 1
    head.ichan = head.ichan';
end
temp = size(head.vchan)
if temp(2) > 1
    head.vchan = head.vchan';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% REMOVE THIS BEFORE PRODUCTION COMMIT     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% subset rtp for faster debugging
%%%% JUST GRAB THE FIRST 100 OBS
% $$$ fprintf(1, '>>> SUBSETTING PROF FOR DEBUG\n');
% $$$ iTest =(1:1000);
% $$$ prof_sub = prof;
% $$$ prof = rtp_sub_prof(prof_sub, iTest);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Need this later
ichan_ccast = head.ichan;

% Add profile data
% $$$ fprintf(1, '>>> Running fill_era... ');
% $$$ [prof,head, pattr]=fill_era(prof,head,pattr);
fprintf(1, '>>> Running fill_ecmwf... ');
[prof,head,pattr]=fill_ecmwf(prof,head,pattr);
fprintf(1, 'Done\n');

% rtp now has profile and obs data ==> 5
head.pfields = 5;
[nchan,nobs] = size(prof.robs1);
head.nchan = nchan;
head.ngas=2;


% Add landfrac, etc.
fprintf(1, '>>> Running usgs_10dem... ');
[head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof, ...
                                               pattr);
fprintf(1, 'Done\n');

% Add Dan Zhou's emissivity and Masuda emis over ocean
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
% $$$ fprintf(1, '>>> Running rtp_ad_emis...');
% $$$ [prof,pattr] = rtp_add_emis(prof,pattr);
% $$$ fprintf(1, 'Done\n');
fprintf(1, '>>> Running add_emis... ');
[prof,pattr] = rtp_add_emis_single(prof,pattr);
fprintf(1, 'Done\n');

% Subset for quicker debugging
% prof = rtp_sub_prof(prof, 1:10:length(prof.rlat));

% run Sergio's subsetting routine
px = prof;
% $$$ px = rmfield(prof,'rcalc');
hx = head; hx.pfields = 5;

prof = uniform_clear_template_lowANDhires_HP(hx,hattr,px,pattr); %% super (if it works)
% for redo of random subset. There are some issues with Sergio's
% code that we are trying to find a way around. THIS WILL NOT WORK
% FOR OTHER SUBSETS
% $$$ fprintf(1, '>>> Running hha_lat_subsample... ');
% $$$ [irand,irand2] = hha_lat_subsample_equal_area2_cris_hires(head, prof);
% $$$ if numel(irand) == 0
% $$$     fprintf(2, ['>>> ERROR : No random obs returned. Skipping to ' ...
% $$$                 'next granule.\n'])
% $$$     return;
% $$$ end
% $$$ 
% $$$ prof = rtp_sub_prof(prof,irand)
% $$$ fprintf(1, 'Done\n');

% run klayers
fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
fprintf(1, '>>> Writing klayers input temp file %s ...', fn_rtp1);
rtpwrite(fn_rtp1,head,hattr,prof,pattr)
fprintf(1, 'Done\n')
fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
run_klayers=[klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath ...
             '/klayers_' sID '_stdout']
fprintf(1, '>>> Running klayers: %s ...', run_klayers);
unix([klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath ...
      '/klayers_' sID '_stdout'])
fprintf(1, 'Done\n');
fprintf(1, '>>> Reading klayers output... ');
[head, hattr, prof, pattr] = rtpread(fn_rtp2);
fprintf(1, 'Done\n');


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
%%** fiasi is a LUT for the IASI frequency space channel
%%allocations
ltemp = load('/asl/data/iremis/danz/iasi_f', 'fiasi'); % load fiasi
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
opt.resmode = 'lowres'; % CrIS mode after Dec. 4, 2014
opt.nguard = nguard; % adding 0 guard channels

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
head.pfields = 7;

% output rtp splitting from airxbcal processing
% Subset into four types and save separately
iclear = find(prof.iudef(1,:) == 1);
% $$$ isite  = find(prof.iudef(1,:) == 2);
% $$$ idcc   = find(prof.iudef(1,:) == 4);
% $$$ irand  = find(prof.iudef(1,:) == 8);
% $$$ irand = 1;

prof_clear = rtp_sub_prof(prof,iclear);
% $$$ prof_site  = rtp_sub_prof(prof,isite);
% $$$ prof_dcc   = rtp_sub_prof(prof,idcc);
% $$$ prof_rand  = rtp_sub_prof(prof,irand);
% $$$ prof_rand = prof;

% $$$ if iclear ~= 0
% $$$     rtp_out_fn = [rtp_out_fn_head, '_clear.rtp'];
% $$$     rtp_outname = fullfile(sTempPath,  rtp_out_fn);
% $$$     fprintf(1, '>>> writing output rtp file %s to local scratch... ', rtp_outname);
% $$$     try
% $$$         rtpwrite(rtp_outname,head,hattr,prof_rand,pattr);
% $$$     catch
% $$$         fprintf(2, '>>> ERROR: rtpwrite of scratch output failed\n');
% $$$         return;
% $$$     end
% $$$     fprintf(1, 'Done\n');
% $$$     
% $$$ end

% Make directory if needed
% cris lowres data will be stored in
% /asl/data/rtp_cris_ccast_lowres/{clear,dcc,site,random}/<year>/<doy>
%
% $$$ asType = {'clear', 'site', 'dcc', 'random'};
asType = {'clear'};
rtp_out_fn_head = ['ecmwf', fnCrisOutput];
rtp_out_fn = [rtp_out_fn_head, '_isarta_clear.rtp'];
cris_out_dir = '/asl/rtp/rtp_cris_ccast_lowres';
% $$$ cris_out_dir = '/home/sbuczko1/WorkingFiles/rtp_cris_ccast_lowres';
rtp_outname2 = fullfile(cris_out_dir, char(asType(1)),cris_yearstr, ...
                        cris_doystr,  rtp_out_fn);
for i = 1:length(asType)
% check for existence of output path and create it if necessary. This may become a source
% for filesystem collisions once we are running under slurm.
    sPath = fullfile(cris_out_dir,char(asType(i)),cris_yearstr,cris_doystr);
    if exist(sPath) == 0
        mkdir(sPath);
    end
end
% $$$ fprintf(1, '>>> moving scratch outputfile to lustre ...\n');
% $$$ fprintf(1, '\t %s --> %s\n', rtp_outname, rtp_outname2);
% $$$ movefile(rtp_outname, rtp_outname2);
% $$$ fprintf(1, 'Done\n');
% $$$

% Now save the four types of cris files
% if no profiles are captured in a subset, do not output a file
if iclear ~= 0
    rtp_out_fn = [rtp_out_fn_head, '_clear.rtp'];
    rtp_outname = fullfile(cris_out_dir,char(asType(1)),cris_yearstr,  cris_doystr, rtp_out_fn);
    rtpwrite(rtp_outname,head,hattr,prof_clear,pattr);
end
% $$$ 
% $$$ if isite ~= 0
% $$$     rtp_out_fn = [rtp_out_fn_head, '_site.rtp'];
% $$$     rtp_outname = fullfile(cris_out_dir, char(asType(2)),cris_yearstr, cris_doystr,  rtp_out_fn);
% $$$     rtpwrite(rtp_outname,head,hattr,prof_site,pattr);
% $$$ end
% $$$ 
% $$$ if idcc ~= 0
% $$$     rtp_out_fn = [rtp_out_fn_head, '_dcc.rtp'];
% $$$     rtp_outname = fullfile(cris_out_dir, char(asType(3)),cris_yearstr, cris_doystr,  rtp_out_fn);
% $$$     rtpwrite(rtp_outname,head,hattr,prof_dcc,pattr);
% $$$ end

fprintf(1, 'Done\n');
