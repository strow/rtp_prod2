function process_cris_hires(fnCrisInput, fnCrisOutput)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS .mat granule file.

% $$$ klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
% $$$ sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';
addpath(genpath('/asl/matlib'));

% guard channels
nguard = 4;

% read in CrIS .mat file and reformat as rtp data structures
[head, hattr, prof, pattr] = ccast2rtp(fnCrisInput, nguard);

% Add weather/climate model
[prof,head]=fill_ecmwf(prof,head);
head.pfields = 5;

% Add surface topography profile
[head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

% Add emissivity
[head,hattr,prof,pattr]=rtpadd_emis_DanZhou(head,hattr,prof,pattr);

% Write first rtp output file (this will be input to klayers/sarta runs
fprintf(1, '>>> Saving first rtp file... ');
[sTempPath, sID] = getslurminfo();
fn_rtp1 = fullfile(sTempPath, [sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr)
fprintf(1, 'Done\n');

% $$$ % run klayers
% $$$ fprintf(1, '>>> running klayers... ');
% $$$ fn_rtp2 = fullfile(sTempPath, [sID '_2.rtp']);
% $$$ klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > /asl/s1/strow/kout.txt'];
% $$$ [status, cmdout] = system(klayers_run);
% $$$ fprintf(1, 'Done\n');
% $$$ 
% $$$ % Run sarta
% $$$ fprintf(1, '>>> Running sarta... ');
% $$$ fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
% $$$ sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ];
% $$$ [status, cmdout] = system(sarta_run);
% $$$ fprintf(1, 'Done\n');

% run klayers and sarta 
r888 = cris888_sarta_wrapper_bc(fn_rtp1, nguard);

% run iasi_to_cris888_grid  (what is the purpose of this step?)
rad_iasi = r888;  % is this correct? should r888 be the input to
                  % the next step? *** if this is correct, make it
                  % just one variable ***
atype = 'box';
crisband_fstart = [ 648.75, 1208.75, 2153.75];
crisband_df = [0.625, 0.625, 0.625]; % 8, 8, 8 mm OPD
crisband_fend = [1096.25, 1751.25, 2551.25];
[f_cris, rad_cris] = iasi_to_cris888_grid(rad_iasi, atype, ...
                                          crisband_fstart, crisband_df, crisband_fend); 

prof.robs1 = rad_cris;
head.pfields=7

% write output rtp file
rtpwrite(fnCrisOutput, head, hattr, prof, pattr);

% temporary files are no longer needed. delete them to make sure we
% don't fill up the scratch drive.
delete(fn_rtp1);

%% ****end function process_cris_hires****

