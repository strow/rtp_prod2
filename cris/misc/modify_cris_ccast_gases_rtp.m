function [head, hattr, prof, pattr] = ...
    modify_cris_ccast_gases_rtp(fnCrisInput, fnGasFile, fnPrescale, ...
                                fnPostscale)
% 
% Reprocess existing cris lowres rtp files and re-run calcs with
% iasi rta
% 

% $$$ cfg.model = 'ecmwf';
% $$$ cfg.sarta_exec = '/asl/bin/crisg4_oct16';
% $$$ cfg.tag = 'csarta';

%set_process_dirs;

fprintf(1, '>> Running modify_cris_ccast_ch4_rtp for input: %s\n', ...
        fnCrisInput);
addpath /home/sbuczko1/git/rtp_prod2/extutils  %
                                         % equal_area_spherical_bands

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';

% $$$ sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
% $$$                'sarta_iasi_may09_wcon_nte'];
% $$$ sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
% $$$                'sarta_crisg4_nov09_wcon_nte'];  %% lowres
sarta_exec = '/asl/bin/crisg4_oct16';

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

% calculate latitude bins
nbins=20; % gives 2N+1 element array of lat bin boundaries
latbins = equal_area_spherical_bands(nbins);
nlatbins = length(latbins);

fprintf(1, '>> Trace data:\n');
trace.klayers = klayers_exec;
fprintf(1, '>>> klayers : %s  (from existing rtp run)\n', trace.klayers);
trace.sarta = sarta_exec;
fprintf(1, '>>> sarta : %s\n', trace.sarta);
func_name='modify_cris_ccast_ch4_rtp';
trace.githash = githash(func_name);
fprintf(1, '>>> githash for %s : %s\n', func_name, trace.githash);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                              'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> run date : %s\n', trace.RunDate);

% generate output filename
% $$$ [pathstr,name,ext] = fileparts(fnCrisInput);
% $$$ C = strsplit(name, '_');
% $$$ fnCrisOutput = fullfile(pathstr, [strjoin({C{1:3} 'csarta' 'ch4x12' C{6:7}}, ...
% $$$                                           '_') ext]);
% $$$ fprintf(1, '>>  Modifying %s for output as %s\n', fnCrisInput, fnCrisOutput);


% Load up rtp
try
    [head, hattr, prof, pattr] = rtpread(fnCrisInput);
catch
    fprintf(2, '>>> ERROR: rtpread failed for %s\n', ...
            fnCrisInput);
    return;
end

% sarta is choking on the 90k obs in the current files
SAVETHISMANY = 75000;
pind = randperm(length(prof.rtime), SAVETHISMANY);
prof = rtp_sub_prof(prof,pind);
rtpwrite(fnPrescale, head, hattr, prof, pattr);


% run klayers on the loaded rtp (first remove p.rclr)
prof = rmfield(prof, 'rclr');

fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr);
fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
unix([klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath '/klayers_stdout']);
[h,ha,p,pa] = rtpread(fn_rtp2);

%%%%%%
% modify CO2 column contents (p.gas_2) by multiplicative factor
scaleCO2 = 401/385;
p.gas_2 = p.gas_2 * scaleCO2;

% modify CH4 column contents (p.gas6)(varies by position over short
% timescales. Modifying by latbins for now)

% modify CO column contents (p.gas_5)(varies by position over short
% timescales. Modifying by latbins for now)
% *** both CH4 and CO will be modified on same latbin structure so
% *** do within a single loop

% load Sergio's retrieval results for CH4 and CO
scalearrays={'xsergioCH4','xsergioCO'};
scale=load(fnGasFile,scalearrays{:});

for ilat = 1:nlatbins-1
    % subset based on latitude bin
    inbin = find(p.rlat > latbins(ilat) & p.rlat <= ...
                 latbins(ilat+1));
    p.gas_5(:,inbin) = p.gas_5(:,inbin)*scale.xsergioCO(ilat);
    p.gas_6(:,inbin) = p.gas_6(:,inbin)*scale.xsergioCH4(ilat);
end
%%%%%%%

fn_rtp2a = fullfile(sTempPath, [sID '_2a.rtp']);
rtpwrite(fn_rtp2a,h,ha,p,pa)
clear h ha p pa

% run cris sarta
fprintf(1, '>>> Running sarta... ');
fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
sarta_run = [sarta_exec ' fin=' fn_rtp2a ' fout=' fn_rtp3 ...
             ' > ' sTempPath '/sartaout.txt'];
unix(sarta_run);

% read in sarta results to capture rcalc
[h,h,p,pa] = rtpread(fn_rtp3);
fprintf(1, 'Done\n');

% Insert rcalc for CrIS derived from IASI SARTA
prof.rclr = p.rcalc;
clear h ha p pa
head.pfields = 7;

% modify header attributes for traceability
% $$$ hattr{end+1}={'header' 'klayers' trace.klayers};
hattr{end+1}={'header' 'sarta' trace.sarta};
hattr{end+1}={'header' 'githash' trace.githash};
hattr{end+1}={'header' 'moddate' trace.RunDate};
hattr{end+1}={'header' 'modfile' fnGasFile};

% write out scaled results
rtpwrite(fnPostscale, head, hattr, prof, pattr);