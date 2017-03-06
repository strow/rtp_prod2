function create_airibrad_allfov_rtp(year, doy)
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
func_name = 'create_airibrad_allfov_rtp';

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';

% Execute user-defined paths
dn = '/asl/data/airs/AIRIBRAD';  % input granules path
airibrad_out_dir = '/home/sbuczko1/WorkingFiles/rtp_airibrad_v5';
addpath /asl/packages/rtp_prod2/util
addpath /asl/packages/rtp_prod2/grib
addpath /asl/packages/rtp_prod2/emis
addpath /asl/packages/rtp_prod2/airs
addpath /home/sbuczko1/git/swutils

trace.klayers = klayers_exec;
trace.sarta = sarta_exec;
trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

% Strings needed for file names
airs_doystr  = sprintf('%03d',doy);
airs_yearstr = sprintf('%4d',year);

% Make output directory if needed
asType = {'allfov'};
for i = 1:length(asType)
    sPath = fullfile(airibrad_out_dir,char(asType(i)),airs_yearstr,airs_doystr);
    if exist(sPath) == 0
        mkdir(sPath);
    end
end

% find list of available input granules
indir = fullfile(dn, airs_yearstr, airs_doystr);
fn = dir(fullfile(indir, '*.hdf'));

for i = 1:length(fn)

    % Read the AIRIBRAD file
    infile = fullfile(indir,fn(i).name);
    fprintf(1, '>>> Reading input file: %s   ', infile);
    [eq_x_tai, freq, prof, pattr] = read_airibrad(infile);
    fprintf(1, 'Done\n');

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

    % Header 
    head = struct;
    head.pfields = 4;  % robs1, no calcs in file
    head.ptype = 0;    
    head.ngas = 0;

    % Assign header attribute strings
    hattr={ {'header' 'pltfid' 'Aqua'}, ...
            {'header' 'instid' 'AIRS'}
            {'header' 'githash' trace.githash}, ...
            {'header' 'rundate' trace.RunDate} };

    nchan = size(prof.robs1,1);
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

    % Fix for zobs altitude units
    if isfield(prof,'zobs')
        iz = prof.zobs < 20000 & prof.zobs > 20;
        prof.zobs(iz) = prof.zobs(iz) * 1000;
    end

    % Add in model data
    fprintf(1, '>>> Running fill_era... ');
    [prof,head,pattr]  = fill_era(prof,head,pattr);
    head.pfields = 5;
    fprintf(1, 'Done\n');

    % Dan Zhou's one-year climatology for land surface emissivity and
    % standard routine for sea surface emissivity
    fprintf(1, '>>> Running rtp_add_emis...');
    [prof,pattr] = rtp_add_emis(prof,pattr);
    fprintf(1, 'Done\n');

    % Save the rtp file
    fprintf(1, '>>> Saving first rtp file... ');
    [sID, sTempPath] = genscratchpath();
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

    rtp_out_fn_head = ['allfov_era_airibrad_day_' airs_yearstr airs_doystr ...
                '.rtp'];
    fprintf(1, '>>> writing output rtp files... ');
    rtp_out_fn = fullfile(sPath, rtp_out_fn_head);
    rtpwrite(rtp_out_fn, head, hattr, prof, pattr);

end
fprintf(1, 'Done\n');


