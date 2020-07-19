function  fix_fill_era(rtpfile)
% FIX_FILL_ERA 
%
% 

% open requested rtp file and read in structures


% run current fill_era verison
[p, h, pa] = fill_era(p, h, pa)

% first split the spectrum & save a copy of each half

tmp = mktemp();
outfiles = rtpwrite_12(tmp,hd,ha,pd,pa);
s1Path = '/tmp/';
%disp(['tmp = ', tmp]);

ifn_1 = outfiles{1};     ifn_2 = outfiles{2};
ofn_1 = [tmp '.kla_1'];  ofn_2 = [tmp '.kla_2'];
ofn_3 = [tmp '.sar_1'];  ofn_4 = [tmp '.sar_2'];

% run klayers on first half
%unix([klayers_exec ' fin=' ifn_1 ' fout=' ofn_1 ' > ' s1Path '/klayers_stdout']);
unix([klayers_exec ' fin=' ifn_1 ' fout=' ofn_1 ' > /dev/null']);

% run sarta on first half
%eval(['! ' sarta_exec ' fin=' ofn_1 ' fout=' ofn_3 ' > sartastdout1.txt']);
eval(['! ' sarta_exec ' fin=' ofn_1 ' fout=' ofn_3 ' > /dev/null']);

% run klayers on second half
%unix([klayers_exec ' fin=' ifn_2 ' fout=' ofn_2 ' > ' s1Path '/klayers_stdout']);
unix([klayers_exec ' fin=' ifn_2 ' fout=' ofn_2 ' > /dev/null']);

% run sarta on second half
%eval(['! ' sarta_exec ' fin=' ofn_2 ' fout=' ofn_4 ' > sartastdout1.txt']);
eval(['! ' sarta_exec ' fin=' ofn_2 ' fout=' ofn_4 ' > /dev/null']);

% read the results files back in
cfin = [tmp '.sar'];

[hd ha pd pa] = rtpread_12(cfin);


%% ****end function fix_fill_era****