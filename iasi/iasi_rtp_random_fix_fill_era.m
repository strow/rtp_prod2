function  iasi_rtp_random_fix_fill_era(rtpfile)
% IASI_RTP_RANDOM_FIX_FILL_ERA 
%
%
func_name = 'iasi_rtp_random_fix_fill_era';

addpath(genpath('/home/sergio/MATLABCODE/matlib/'));  % driver_sarta_cloudy
addpath /asl/packages/rtp_prod2/grib
addpath /asl/packages/rtp_prod2/util
addpath /asl/matlib/rtptools
addpath /asl/matlib/aslutil
addpath /home/sbuczko1/git/swutils

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte';
sartacldy_exec = ['/asl/packages/sartaV108/BinV201/' ...
                  'sarta_iasi_may09_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte_swch4'];

[sID, sTempPath] = genscratchpath();

trace.klayers = klayers_exec;
trace.sarta = sarta_exec;
trace.sartacldy = sartacldy_exec;
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

% $$$ % reset h.ptype to 0 so that klayers will run (should be 1 in the
% $$$ % as-read rtp file)
% $$$ h.ptype = 0;

% $$$ % remove p.plevs
% $$$ fprintf(1,'>>> Removing p.plevs\n');
% $$$ p=rmfield(p, 'plevs');
% $$$ p=rmfield(p, 'txover');
% $$$ p=rmfield(p, 'gxover');

% simplify prof and head structs
fprintf(1,'>>> Simplify prof/head\n');
[h, p] = strip_prof(h, p);

% run current fill_era verison
fprintf(1, '>>> Running fill_era\n');
[p, h, pa] = fill_era(p, h, pa);

h.pfields = 5;
[nchan,nobs] = size(p.robs1);
h.nchan = nchan;
h.ngas=2;

% Add surface
fprintf(1, '>>> Add topography\n');
[h,ha,p,pa] = rtpadd_usgs_10dem(h,ha,p,pa);

% Add emissivity
fprintf(1, '>>> Add emmissivity\n');
[p,pa] = rtp_add_emis_single(p,pa);

% test subsetting to reduce obs. Fighting with rtpwrite failure in driver_sarta_cloudy
% $$$ pd = rtp_sub_prof(p,1:100);
% $$$ p=pd;
% $$$ clear pd

% first split the spectrum & save a copy of each half
tmp = fullfile(sTempPath, 'fix_rtp');
outfiles = rtpwrite_12(tmp,h,ha,p,pa);

ifn_1 = outfiles{1};     ifn_2 = outfiles{2};
ofn_1 = [tmp '.kla_1'];  ofn_2 = [tmp '.kla_2'];
ofn_3 = [tmp '.sar_1'];  ofn_4 = [tmp '.sar_2'];

% $$$ % run klayers on first half
% $$$ fprintf(1, '>>> Klayers: first half\n');
% $$$ %unix([klayers_exec ' fin=' ifn_1 ' fout=' ofn_1 ' > ' s1Path '/klayers_stdout']);
% $$$ unix([klayers_exec ' fin=' ifn_1 ' fout=' ofn_1 ' > /dev/null']);
% $$$ 
% $$$ % run klayers on second half
% $$$ fprintf(1, '>>> klayers: second half\n');
% $$$ %unix([klayers_exec ' fin=' ifn_2 ' fout=' ofn_2 ' > ' s1Path '/klayers_stdout']);
% $$$ unix([klayers_exec ' fin=' ifn_2 ' fout=' ofn_2 ' > /dev/null']);

% driver_sarta_cloudy runs klayers
% run sarta on first half
fprintf(1, '>>> sarta: first half\n');
% call klayers/sarta cloudy
run_sarta.cloud=+1;
run_sarta.clear=+1;
run_sarta.cumsum=9999;
run_sarta.klayers_code = klayers_exec;
run_sarta.sartaclear_code = sarta_exec;
run_sarta.sartacloud_code = sartacldy_exec;
run_sarta.ForceNewSlabs = -1;  
% driver_sarta_cloud_rtp ultimately looks for default sarta
% executables in Sergio's directories. **DANGEROUS** These need to
% be brought under separate control for traceability purposes.

% read in klayers output for pass to sarta cloudy
[head, hattr, prof, pattr] = rtpread(ifn_1);

% $$$ [prof0, oslabs] = driver_sarta_cloud_rtp(h,ha,p,pa,run_sarta);
[prof0, oslabs] = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);
% $$$ try
% $$$     [prof0, oslabs] = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);
% $$$ catch
% $$$     fprintf(2, ['>>> ERROR: failure in driver_sarta_cloud_rtp step 1 for ' ...
% $$$                 '%s\n'], rtpfile);
% $$$     return;
% $$$ end

% write out single rtp file for first sarta output
rtpwrite(ofn_3, head, hattr, prof0, pattr);

% run sarta on second half
% copy cloud slab params frmo first run into prof for this run to
% maintain cloud slab model (otherwise, slabs will get randomized
% and the two halves won't match up).  Also make sure h.ichan and
% h.vchan are set appropriately for the second band.

% ** might be easier to use output profile from above and replace
% robs1 with those for the second band?? **
fprintf(1, '>>> sarta: second half\n');

% read in klayers output for pass to sarta cloudy
[head, hattr, prof, pattr] = rtpread(ifn_2);

[prof0, oslabs] = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);
% $$$ try
% $$$     [prof0, oslabs] = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);
% $$$ catch
% $$$     fprintf(2, ['>>> ERROR: failure in driver_sarta_cloud_rtp step 2 for ' ...
% $$$                 '%s\n'], rtpfile);
% $$$     return;
% $$$ end

% write out single rtp file for second sarta output
rtpwrite(ofn_4, head, hattr, prof0, pattr);


% move results to output directory
fprintf(1, '>>> moving files\n');
[pathstr, fname, ext] = fileparts(rtpfile);
% break path down to remove 'Old' leaf
% $$$ C = strsplit(pathstr, '/');  % 'Old' is C{end}
% $$$ basepath = fullfile('/', C{1:end-1});
outfilebase = fullfile(pathstr, [fname '-cldy.rtp']);
movefile(ofn_3, [outfilebase '_1']);
movefile(ofn_4, [outfilebase '_2']);

% $$$ % since we have the point profiles also available, let's just go
% $$$ % ahead an save them in ${basepath}/Point/*.rtp_[12]
% $$$ mkdir(basepath, 'Point')
% $$$ outfiles = rtpwrite_12(fullfile(basepath, 'Point', [fname '.rtp']), h,ha,p,pa);

%% ****end function fix_fill_era****