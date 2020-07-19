function [h, ha, p, pa] = run_sarta(head, hattr, prof, pattr, opt)
% RUN_KLAYERS 
%
% run klayers on the rtp data to convert pressure levels to AIRS
% layers
%
% REQUIRES:
%   addpath /asl/packages/rtp_prod2/util  for rtpwrite, rtpread, genscratchpath

%
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';

opt.sarta = sarta_exec;

sID = opt.sID;
sTempPath = opt.sTempPath;

fprintf(1, '>>> running sarta...\n\t(using %s)\n', sarta_exec);

% establish temporary files (most likely in /scratch)
%fn_rtp1 = fullfile(basedir,dayfiles(giday).name);
fn_rtp1 = fullfile(sTempPath, ['sarta_' sID '_1.rtp']);
fn_rtp2 = fullfile(sTempPath, ['sarta_' sID '_2.rtp']);

% write rtp sturctures out to make input file for sarta
rtpwrite(fn_rtp1, head, hattr, prof, pattr);

% run sarta
sarta_run = [sarta_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ...
               ' > ' sTempPath '/kout.txt'];
unix(sarta_run);

% read in sarta output and pass back to calling function
[h,ha,p,pa] = rtpread(fn_rtp2);

% add sarta executable path to header attributes
ha{end+1} = {'header' 'sarta' sarta_exec};

fprintf(1, 'Done\n');

%% ****end function run_sarta****