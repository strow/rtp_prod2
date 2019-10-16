function modify_cris_ccast_lowres_iasi_rtp(fnCrisInput)
% 
% Reprocess existing cris lowres rtp files and re-run calcs with
% iasi rta
% 

%set_process_dirs;

fprintf(1, '>> Running modify_cris_ccast_lowres_rtp for input: %s\n', ...
        fnCrisInput);

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
               'sarta_iasi_may09_wcon_nte'];
% $$$ sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
% $$$                'sarta_crisg4_nov09_wcon_nte'];  %% lowres

% $$$ addpath /home/sbuczko1/git/rtp_prod2/cris/readers  % ccast2rtp
addpath(genpath('/asl/matlib'));
% Need these two paths to use iasi2cris.m in iasi_decon
addpath /asl/packages/iasi_decon
addpath /asl/packages/ccast/source
addpath /asl/packages/rtp_prod2/cris
addpath /asl/packages/rtp_prod2/util
addpath /asl/packages/swutils   % githash
% $$$ addpath /asl/packages/rtp_prod2/emis
% $$$ addpath /asl/packages/rtp_prod2/grib

[sID, sTempPath] = genscratchpath();
sID = getenv('SLURM_ARRAY_TASK_ID');
nguard = 2;  % number of guard channels

fprintf(1, '>> Trace data:\n');
trace.klayers = klayers_exec;
fprintf(1, '>>> klayers : %s  (from existing rtp run)\n', trace.klayers);
trace.sarta = sarta_exec;
fprintf(1, '>>> sarta : %s\n', trace.sarta);
func_name='modify_cris_ccast_lowres_iasi_rtp';
trace.githash = githash(func_name);
fprintf(1, '>>> githash for %s : %s\n', func_name, trace.githash);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                              'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> run date : %s\n', trace.RunDate);

% generate output filename
[pathstr,name,ext] = fileparts(fnCrisInput);
C = strsplit(name, '_');
fnCrisOutput = fullfile(pathstr, [strjoin({C{1:4} 'isarta' C{5}}, ...
                                          '_') ext]);
fprintf(1, '>>  Modifying %s for output as %s\n', fnCrisInput, fnCrisOutput);


% Load up rtp
try
    [head, hattr, prof, pattr] = rtpread(fnCrisInput);
catch
    fprintf(2, '>>> ERROR: rtpread failed for %s\n', ...
            fnCrisInput);
    return;
end

% Need this later
ichan_ccast = head.ichan;

% $$$ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% $$$ %%%% REMOVE THIS BEFORE PRODUCTION COMMIT     %%%%
% $$$ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% $$$ %%%% subset rtp for faster debugging
% $$$ %%%% JUST GRAB THE FIRST 100 OBS
% $$$ fprintf(1, '>>> SUBSETTING PROF FOR DEBUG\n');
% $$$ iTest =(1:1000);
% $$$ prof_sub = prof;
% $$$ prof = rtp_sub_prof(prof_sub, iTest);
% $$$ clear prof_sub;
% $$$ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% $$$ % reset ptype so we can re-run klayers
% $$$ h.ptype = 0;
% $$$ 
% $$$ % run klayers
% $$$ fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
% $$$ fprintf(1, '>>> Writing klayers input temp file %s ...', fn_rtp1);
% $$$ rtpwrite(fn_rtp1,head,hattr,prof,pattr)
% $$$ fprintf(1, 'Done\n')
% $$$ fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
% $$$ run_klayers=[klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath ...
% $$$              '/klayers_' sID '_stdout']
% $$$ fprintf(1, '>>> Running klayers: %s ...', run_klayers);
% $$$ unix([klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath ...
% $$$       '/klayers_' sID '_stdout'])
% $$$ fprintf(1, 'Done\n');
% $$$ fprintf(1, '>>> Reading klayers output... ');
% $$$ [head, hattr, prof, pattr] = rtpread(fn_rtp2);
% $$$ fprintf(1, 'Done\n');

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

% Go get output from klayers, which is what we want except for
% rcalc
clear head hattr prof pattr;
[head, hattr, prof, pattr] = rtpread(fnCrisInput);

% Insert rcalc for CrIS derived from IASI SARTA
prof.rcalc = real(rad_cris); 
head.pfields = 7;

% modify header attributes for traceability
% $$$ hattr{end+1}={'header' 'klayers' trace.klayers};
hattr{end+1}={'header' 'sarta' trace.sarta};
hattr{end+1}={'header' 'githash' trace.githash};
hattr{end+1}={'header' 'moddate' trace.RunDate};

% now resave rtp file
rtpwrite(fnCrisOutput, head, hattr, prof, pattr);

fprintf(1, 'Done\n');
