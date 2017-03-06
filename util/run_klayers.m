function [h, ha, p, pa] = run_klayers(head, hattr, prof, pattr, opt)
% RUN_KLAYERS 
%
% run klayers on the rtp data to convert pressure levels to AIRS
% layers
%
% REQUIRES:
%   addpath /asl/packages/rtp_prod2/util  for rtpwrite, rtpread, genscratchpath

% 
klayers_exec = ['/asl/packages/klayersV205/BinV201/' ...
                'klayers_airs_wetwater'];

opt.klayers = klayers_exec;

sID = opt.sID;
sTempPath = opt.sTempPath;

fprintf(1, '>>> running klayers...\n\t(using %s)\n', klayers_exec);

% establish temporary files (most likely in /scratch)
%fn_rtp1 = fullfile(basedir,dayfiles(giday).name);
fn_rtp1 = fullfile(sTempPath, ['klayers_' sID '_1.rtp']);
fn_rtp2 = fullfile(sTempPath, ['klayers_' sID '_2.rtp']);

% write rtp sturctures out to make input file for klayers
rtpwrite(fn_rtp1, head, hattr, prof, pattr);

% run klayers
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ...
               ' > ' sTempPath '/kout.txt'];
unix(klayers_run);

% read in klayers output and pass back to calling function
[h,ha,p,pa] = rtpread(fn_rtp2);

% add klayers executable path to header attributes
ha{end+1} = {'header' 'klayers' klayers_exec};

fprintf(1, 'Done\n');

%% ****end function run_klayers****