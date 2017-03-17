function  iasi_rtp_fix_fill_era(rtpfile)
% IASI_RTP_FIX_FILL_ERA 
%
%
func_name = 'iasi_rtp_fix_fill_era';

addpath /asl/packages/rtp_prod2/grib
addpath /asl/packages/rtp_prod2/util
addpath /asl/matlib/rtptools
addpath /asl/packages/swutils

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
% $$$ sarta_exec   = ['/asl/packages/sartaV108/BinV201/' ...
% $$$                 'sarta_iasi_may09_wcon_nte'];
sarta_exec   = '/asl/bin/sarta_iasi_may09_wcon_nte';

[sID, sTempPath] = genscratchpath();

trace.klayers = klayers_exec;
trace.sarta = sarta_exec;
trace.githash = githash(func_name);
trace.fillera = githash('fill_era');
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

% open requested rtp file and read in structures
fprintf(1, '>>> reading input rtp file %s\n', rtpfile);
[h,ha,p,pa] = rtpread_12(rtpfile);

% add run traceability info to header attributes
fprintf(1, '>>> Adding traceability info\n');
ha{end+1} = {'header' 'githash' trace.githash};
% $$$ ha{end+1} = {'header' 'fill_era' trace.fillera};
ha{end+1} = {'header' 'rundate' trace.RunDate};
% $$$ ha{end+1} = {'header' 'sarta' trace.sarta};
% $$$ ha{end+1} = {'header' 'klayers' trace.klayers};

% simplify prof and head structs
fprintf(1,'>>> Simplify prof/head\n');
[h, p] = strip_prof(h, p);

% run current fill_era verison
fprintf(1, '>>> Running fill_era\n');
[p, h, pa] = fill_era(p, h, pa);
h.pfields = 5;

% Add surface
fprintf(1, '>>> Add topography\n');
[h,ha,p,pa] = rtpadd_usgs_10dem(h,ha,p,pa);

% Add emissivity
fprintf(1, '>>> Add emmissivity\n');
[p,pa] = rtp_add_emis_single(p,pa);

% first split the spectrum & save a copy of each half
fprintf(1, '>>> Write temp file for klayers/sarta input\n');
tmp = fullfile(sTempPath, 'fix_rtp');
outfiles = rtpwrite_12(tmp,h,ha,p,pa);

ifn_1 = outfiles{1};     ifn_2 = outfiles{2};
ofn_1 = [tmp '.kla_1'];  ofn_2 = [tmp '.kla_2'];
ofn_3 = [tmp '.sar_1'];  ofn_4 = [tmp '.sar_2'];

% run klayers on first half
fprintf(1, '>>> Klayers: first half\n');
%unix([klayers_exec ' fin=' ifn_1 ' fout=' ofn_1 ' > ' s1Path '/klayers_stdout']);
unix([klayers_exec ' fin=' ifn_1 ' fout=' ofn_1 ' > /dev/null']);

% run sarta on first half
fprintf(1, '>>> sarta: first half\n');
%eval(['! ' sarta_exec ' fin=' ofn_1 ' fout=' ofn_3 ' > sartastdout1.txt']);
eval(['! ' sarta_exec ' fin=' ofn_1 ' fout=' ofn_3 ' > /dev/null']);

% run klayers on second half
fprintf(1, '>>> klayers: second half\n');
%unix([klayers_exec ' fin=' ifn_2 ' fout=' ofn_2 ' > ' s1Path '/klayers_stdout']);
unix([klayers_exec ' fin=' ifn_2 ' fout=' ofn_2 ' > /dev/null']);

% run sarta on second half
fprintf(1, '>>> sarta: second half\n');
%eval(['! ' sarta_exec ' fin=' ofn_2 ' fout=' ofn_4 ' > sartastdout1.txt']);
eval(['! ' sarta_exec ' fin=' ofn_2 ' fout=' ofn_4 ' > /dev/null']);

% read in sarta output and copy rcalc over to original point
% profile struct
[~, ~, ptmp, ~] = rtpread_12(ofn_3);
p.rcalc = ptmp.rcalc;
clear ptmp

% move results to output directory
fprintf(1, '>>> moving files\n');
[pathstr, fname, ext] = fileparts(rtpfile);
% break path down to remove 'Old' leaf
C = strsplit(pathstr, '/');  % 'Old' is C{end}
basepath = fullfile('/', C{1:end-1});
outfilebase = fullfile(basepath, [fname '.rtp']);
movefile(ofn_3, [outfilebase '_1']);
movefile(ofn_4, [outfilebase '_2']);

% since we have the point profiles also available, let's just go
% ahead an save them in ${basepath}/Point/*.rtp_[12]
mkdir(basepath, 'Point')
outfiles = rtpwrite_12(fullfile(basepath, 'Point', [fname '.rtp']), h,ha,p,pa);

%% ****end function fix_fill_era****