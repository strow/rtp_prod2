function create_airibrad_random_nadir_rtp(infile, outfile_head)
%
% NAME
%   create_airibrad_rtp -- wrapper to process AIRIBRAD to RTP
%
% SYNOPSIS
%   create_airibrad_rtp(infile, outfile_head)
%
% INPUTS
%    infile :   path to input AIRIBRAD hdf file
%    outfile_head  : path to output rtp file (minus extension)
%
% L. Strow, Jan. 14, 2015
%
% DISCUSSION (TBD)

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';

% Execute user-defined paths
set_process_dirs
addpath(genpath(rtp_sw_dir));
addpath('/home/sergio/MATLABCODE/PLOTTER');

% Read the AIRIBRAD file
fprintf(1, '>>> Reading input file: %s   ', infile);
[eq_x_tai, freq, prof0, pattr] = read_airibrad(infile);
fprintf(1, 'Done\n');

% Header 
head = struct;
head.pfields = 4;  % robs1, no calcs in file
head.ptype = 0;    
head.ngas = 0;

% Assign header attribute strings
hattr={ {'header' 'pltfid' 'Aqua'}, ...
        {'header' 'instid' 'AIRS'} };

nchan = size(prof0.robs1,1);
chani = (1:nchan)';
%vchan = aux.nominal_freq(:);
vchan = freq;

% Assign header variables
head.instid = 800; % AIRS 
head.pltfid = -9999;
head.nchan = length(chani);
head.ichan = chani;
head.vchan = vchan(chani);
head.vcmax = max(head.vchan);
head.vcmin = min(head.vchan);

% find random, nadir subset
% uses sergio's hha_...3.m
% need head for input
[keep, nadir_ind] = hha_lat_subsample_equal_area3(head, prof0);
prof = rtp_sub_prof(prof0, nadir_ind);

% subset if nobs is greater than threshold lmax (to avoid hdf file size
% limitations and hdfvs() failures during rtp write/read
% later). Keeps dcc, site and random obs intact and reduces number
% of clear obs to meet threshold limit
lmax = 72000;
fprintf(1, '>>> *** %d pre-subset obs ***\n', length(prof.rtime));
if length(prof.rtime) > lmax
    fprintf(1, '>>>*** nobs > %d. subsetting clear... ', lmax);
    prof = sub_airxbcal(prof, lmax);
    fprintf(1, 'Done ***\n');
    fprintf(1, '>>> *** %d subset obs ***\n', length(prof.rtime));
end

% Fix for zobs altitude units
if isfield(prof,'zobs')
   iz = prof.zobs < 20000 & prof.zobs > 20;
   prof.zobs(iz) = prof.zobs(iz) * 1000;
end

% Add in model data
fprintf(1, '>>> Running fill_era... ');
[prof,head]  = fill_era(prof,head);
head.pfields = 5;
fprintf(1, 'Done\n');

% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_add_emis...');
[prof,pattr] = rtp_add_emis(prof,pattr);
fprintf(1, 'Done\n');

% Save the rtp file
fprintf(1, '>>> Saving first rtp file... ');
sNodeID = getenv('SLURM_PROCID');
sScratchPath = getenv('JOB_SCRATCH_DIR');
if ~isempty(sNodeID) && ~isempty(sScratchPath)
    sTempPath = sScratchPath;
    sID = sNodeID;
else
    sTempPath = '/tmp';
    rng('shuffle');
    sID = sprintf('%03d', randi(999));
end
fn_rtp1 = fullfile(sTempPath, ['airs_' sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr)
fprintf(1, 'Done\n');

% run klayers
fprintf(1, '>>> running klayers... ');
fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               sTempPath '/kout.txt'];
unix(klayers_run);
fprintf(1, 'Done\n');

% Run sarta
% *** split fn_rtp3 into 'N' multiple chunks (via rtp_sub_prof like
% below for clear,site,etc?) make call to external shell script to
% run 'N' copies of sarta backgrounded
fprintf(1, '>>> Running sarta... ');
fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
psarta_run(fn_rtp2, fn_rtp3, sarta_exec);
fprintf(1, 'Done\n');

% Read in new rcalcs and insert into origin prof field
stFileInfo = dir(fn_rtp3);
fprintf(1, ['*************\n>>> Reading fn_rtp3:\n\tName:\t%s\n\tSize ' ...
            '(GB):\t%f\n*************\n'], stFileInfo.name, stFileInfo.bytes/1.0e9);
[h,ha,p,pa] = rtpread(fn_rtp3);
prof.rcalc = p.rcalc;
head.pfields = 7;

% profile attribute changes for airibrad
pa = set_attr('profiles', 'robs1', infile);
pa = set_attr(pa, 'rtime', 'TAI:1958');

%keyboard
% temporary files are no longer needed. delete them to make sure we
% don't fill up the scratch drive.
delete(fn_rtp1, fn_rtp2, fn_rtp3);


%rtp_out_fn_head = ['era_airibrad_day' airs_doystr];
rtp_out_fn_head=outfile_head;
% Now save the four types of airibrad files
fprintf(1, '>>> writing output rtp files... ');
rtp_out_fn = [rtp_out_fn_head '.rtp'];
rtpwrite(rtp_out_fn, head, hattr, prof, pattr);

% $$$ rtp_out_fn = [rtp_out_fn_head, '_clear.rtp'];
% $$$ %rtp_outname = fullfile(airibrad_out_dir,airs_yearstr, char(asType(1)), rtp_out_fn);
% $$$ rtpwrite(rtp_out_fn,head,hattr,prof_clear,pattr);
% $$$ 
% $$$ rtp_out_fn = [rtp_out_fn_head, '_site.rtp'];
% $$$ %rtp_outname = fullfile(airibrad_out_dir,airs_yearstr, char(asType(2)), rtp_out_fn);
% $$$ rtpwrite(rtp_out_fn,head,hattr,prof_site,pattr);
% $$$ 
% $$$ rtp_out_fn = [rtp_out_fn_head, '_dcc.rtp'];
% $$$ %rtp_outname = fullfile(airibrad_out_dir,airs_yearstr, char(asType(3)), rtp_out_fn);
% $$$ rtpwrite(rtp_out_fn,head,hattr,prof_dcc,pattr);
% $$$ 
% $$$ rtp_out_fn = [rtp_out_fn_head, '_rand.rtp'];
% $$$ %rtp_outname = fullfile(airibrad_out_dir,airs_yearstr, char(asType(4)), rtp_out_fn);
% $$$ rtpwrite(rtp_out_fn,head,hattr,prof_rand,pattr);
fprintf(1, 'Done\n');

            