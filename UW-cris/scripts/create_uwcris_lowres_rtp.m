function [head, hattr, prof, pattr] = create_uwcris_lowres_rtp(fnCrisInput)
% CREATE_UWCRIS_LOWRES_RTP process one granule of UW CrIS data
%
% Process a single UW CrIS netcdf granule file.

%set_process_dirs;

% input granule names are of the form:
% SNDR.SNPP.CRIS.20160120T2206.m06.g222.L1B_NSR.std.v01_00_00.W.160311163941.nc
% $$$ files = dir(fnCrisInput)
% $$$ fname = files(1).name;
% $$$ yearstr = fname(16:19);
% $$$ monthstr = fname(20:21);
% $$$ daystr = fname(22:23);
% $$$ doystr = char(datetime([yearstr '-' monthstr '-' daystr], 'Format', ...
% $$$                        'DDD'));
% $$$ grantag = fname(16:37);

fprintf(1, '>> Running create_uwcris_lowres_rtp for input: %s\n', ...
        fnCrisInput);


klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
% $$$ sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
% $$$                'sarta_crisg4_nov09_wcon_nte'];  %% lowres
sarta_exec = '/asl/bin/crisg4_oct16';

addpath(genpath('/asl/matlib'));
% Need these two paths to use iasi2cris.m in iasi_decon
addpath /asl/packages/iasi_decon
addpath /asl/packages/ccast/source
addpath /asl/packages/time
addpath /asl/packages/ccast/motmsc/rtp_sarta
addpath /asl/rtp_prod/cris/unapod  % cris_box_to_ham.m
addpath /home/sbuczko1/git/rtp_prod2/cris
addpath /home/sbuczko1/git/rtp_prod2/util
addpath /home/sbuczko1/git/rtp_prod2/emis
addpath /home/sbuczko1/git/rtp_prod2/grib
addpath /home/sbuczko1/git/rtp_prod2/UW-cris

[sID, sTempPath] = genscratchpath();
sID = getenv('SLURM_ARRAY_TASK_ID');
nguard = 2;  % number of guard channels

opt.resmode = 'hires';

% Load up rtp
try
    [head, hattr, prof, pattr] = uwnc2rtp(fnCrisInput, opt);
catch
    fprintf(2, '>>> ERROR: uwnc2rtp failed for %s\n', ...
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
% $$$ fprintf(1, 'Done\n');
fprintf(1, '>>> Running fill_ecmwf... ');
[prof,head, pattr]=fill_ecmwf(prof,head,pattr);
fprintf(1, 'Done\n');

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
% $$$ hx = head; hx.pfields = 5;

prof = uniform_clear_template_lowANDhires_HP(head,hattr,px,pattr); %% super (if it works)
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
% $$$ fprintf(1, '>>> Reading klayers output... ');
% $$$ [head, hattr, prof, pattr] = rtpread(fn_rtp2);
fprintf(1, 'Done\n');

% Run sarta
% *** split fn_rtp3 into 'N' multiple chunks (via rtp_sub_prof like
% below for clear,site,etc?) make call to external shell script to
% run 'N' copies of sarta backgrounded
fn_rtp3 = fullfile(sTempPath, ['cris_' sID '_3.rtp']);
run_sarta = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ' > ' ...
             sTempPath '/sarta_' sID '_stdout.txt'];
fprintf(1, '>>> Running sarta: %s ...', run_sarta);
unix(run_sarta);
fprintf(1, 'Done\n');

% Read in new rcalcs and insert into origin prof field
% $$$ stFileInfo = dir(fn_rtp3);
% $$$ fprintf(1, ['*************\n>>> Reading fn_rtp3:\n\tName:\t%s\n\tSize ' ...
% $$$             '(GB):\t%f\n*************\n'], stFileInfo.name, stFileInfo.bytes/1.0e9);
fprintf(1, '>>> Reading sarta output... ');
[~,~,p,~] = rtpread(fn_rtp3);
fprintf(1, 'Done\n');

% Go get output from klayers, which is what we want except for rcalc
% $$$ [head, hattr, prof, pattr] = rtpread(fn_rtp2);
% Insert rcalc for CrIS derived from IASI SARTA
prof.rclr = p.rcalc;
head.pfields = 7;
% $$$ 
% $$$ asType = {'clear'};
% $$$ rtp_out_fn_head = ['era_' grantag];
% $$$ rtp_out_dir = '/home/sbuczko1/WorkingFiles/rtp_cris_uw_lowres';
% $$$ 
% $$$ % subset and output to rtp
% $$$ for i = 1:length(asType)
% $$$     % check for existence of output path and create it if necessary. This may become a source
% $$$     % for filesystem collisions once we are running under slurm.
% $$$     sPath = fullfile(rtp_out_dir,char(asType(i)),yearstr,doystr);
% $$$     if exist(sPath) == 0
% $$$         mkdir(sPath);
% $$$     end
% $$$ 
% $$$     switch(char(asType(i)))
% $$$       case 'random'
% $$$ % $$$         obsfound = find(prof.iudef(1,:) == 8);
% $$$         obsfound = irand;
% $$$       case 'clear'
% $$$         obsfound = find(prof.iudef(1,:) == 1);
% $$$       case 'dcc'
% $$$         obsfound   = find(prof.iudef(1,:) == 4);
% $$$       case 'site'
% $$$         obsfound  = find(prof.iudef(1,:) == 2);
% $$$     end
% $$$ 
% $$$     if obsfound ~= 0
% $$$         fprintf(1, '>> OUTPUT : Valid obs found :: %d', length(obsfound));
% $$$         prof_out = rtp_sub_prof(prof,obsfound);
% $$$ % $$$         prof_out = prof_rand;
% $$$         rtp_out_fn = [rtp_out_fn_head '_' char(asType(i)) '.rtp'];
% $$$         rtp_outname = fullfile(rtp_out_dir,char(asType(i)),yearstr, doystr, rtp_out_fn);
% $$$         rtpwrite(rtp_outname,head,hattr,prof_out,pattr);
% $$$     else
% $$$         fprintf(1, '>> OUTPUT : No valid obs found for granule %s\n', ...
% $$$                 fnCrisInput);
% $$$     end
% $$$     
% $$$ end
% $$$ 
% $$$ fprintf(1, 'Done\n');
