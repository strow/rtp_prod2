function create_cris_ccast_lowres_rtp(fnCrisInput, fnCrisOutput)
% PROCESS_CRIS_LOWRES process one granule of CrIS data
%
% Process a single CrIS .mat granule file.

%set_process_dirs;

fprintf(1, '>> Running create_cris_ccast_lowres_rtp for input: %s\n', ...
        fnCrisInput);

% use fnCrisOutput to generate year and doy strings
% fnCrisOutput will be of the form rtp_d<YYYMMDD>_t<granule time>
cris_yearstr = fnCrisOutput(6:9);
month = str2num(fnCrisOutput(10:11));
day = str2num(fnCrisOutput(12:13));
dt = datetime(str2num(cris_yearstr), month, day);
dt.Format = 'DDD';
cris_doystr = char(dt);

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
               'sarta_crisg4_nov09_wcon_nte'];  %% lowres

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
[prof,head]=fill_era(prof,head);
% $$$ [prof,head]=fill_ecmwf(prof,head);
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
% $$$ fprintf(1, '>>> Running rtp_ad_emis...');
% $$$ [prof,pattr] = rtp_add_emis(prof,pattr);
% $$$ fprintf(1, 'Done\n');

[prof,pattr] = rtp_add_emis_single(prof,pattr);

% Subset for quicker debugging
% prof = rtp_sub_prof(prof, 1:10:length(prof.rlat));

% run Sergio's subsetting routine
px = prof;
% $$$ px = rmfield(prof,'rcalc');
hx = head; hx.pfields = 5;
fprintf(1, '>>> NGAS = %d\n', hx.ngas);
disp('>>> Sergio insists on knowing we are here')
prof = uniform_clear_template_lowANDhires_HP(hx,hattr,px,pattr); %% super (if it works)

fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);

rtpwrite(fn_rtp1,head,hattr,prof,pattr)
fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);

% run klayers
unix([klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath '/klayers_stdout'])
[head, hattr, prof, pattr] = rtpread(fn_rtp2);

% Run sarta
% *** split fn_rtp3 into 'N' multiple chunks (via rtp_sub_prof like
% below for clear,site,etc?) make call to external shell script to
% run 'N' copies of sarta backgrounded
fprintf(1, '>>> Running sarta... ');
fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ' > ' ...
             sTempPath '/sartastdout.txt'];
unix(sarta_run);
fprintf(1, 'Done\n');

% Read in new rcalcs and insert into origin prof field
stFileInfo = dir(fn_rtp3);
fprintf(1, ['*************\n>>> Reading fn_rtp3:\n\tName:\t%s\n\tSize ' ...
            '(GB):\t%f\n*************\n'], stFileInfo.name, stFileInfo.bytes/1.0e9);
[h,ha,p,pa] = rtpread(fn_rtp3);
% $$$ prof.rcalc = p.rcalc;
% $$$ head.pfields = 7;

% Go get output from klayers, which is what we want except for rcalc
% $$$ [head, hattr, prof, pattr] = rtpread(fn_rtp2);
% Insert rcalc for CrIS derived from IASI SARTA
prof.rcalc = p.rcalc;
head.pfields = 7;

% output rtp splitting from airxbcal processing
% Subset into four types and save separately
iclear = find(prof.iudef(1,:) == 1);
isite  = find(prof.iudef(1,:) == 2);
idcc   = find(prof.iudef(1,:) == 4);
irand  = find(prof.iudef(1,:) == 8);

prof_clear = rtp_sub_prof(prof,iclear);
prof_site  = rtp_sub_prof(prof,isite);
prof_dcc   = rtp_sub_prof(prof,idcc);
prof_rand  = rtp_sub_prof(prof,irand);

% Make directory if needed
% cris lowres data will be stored in
% /asl/data/rtp_cris_ccast_lowres/{clear,dcc,site,random}/<year>/<doy>
%
asType = {'clear', 'site', 'dcc', 'random'};
cris_out_dir = '/asl/data/rtp_cris_ccast_lowres';
for i = 1:length(asType)
% check for existence of output path and create it if necessary. This may become a source
% for filesystem collisions once we are running under slurm.
    sPath = fullfile(cris_out_dir,char(asType(i)),cris_yearstr,cris_doystr);
    if exist(sPath) == 0
        mkdir(sPath);
    end
end
% $$$
rtp_out_fn_head = fnCrisOutput;
% Now save the four types of cris files
fprintf(1, '>>> writing output rtp files... ');
% if no profiles are captured in a subset, do not output a file
% $$$ if iclear ~= 0
% $$$     rtp_out_fn = [rtp_out_fn_head, '_clear.rtp'];
% $$$     rtp_outname = fullfile(cris_out_dir,char(asType(1)),cris_yearstr,  cris_doystr, rtp_out_fn);
% $$$     rtpwrite(rtp_outname,head,hattr,prof_clear,pattr);
% $$$ end
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

if irand ~= 0
    rtp_out_fn = [rtp_out_fn_head, '_rand.rtp'];
    rtp_outname = fullfile(cris_out_dir, char(asType(4)),cris_yearstr, cris_doystr,  rtp_out_fn);
    rtpwrite(rtp_outname,head,hattr,prof_rand,pattr);
end
fprintf(1, 'Done\n');


% Next delete temporary files
delete(fn_rtp1);delete(fn_rtp2)
