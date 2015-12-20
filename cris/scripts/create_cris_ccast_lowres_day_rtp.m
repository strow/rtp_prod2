function create_cris_ccast_lowres_day_rtp(fnCrisInput)
% PROCESS_CRIS_LOWRES process one day's worth of granules of CrIS data
% concatenate each granule into a single daily rtp file and subset
% for random

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
               'sarta_crisg4_nov09_wcon_nte'];  %% lowres

% $$$ addpath(genpath('/asl/matlib'));
% $$$ % Need these two paths to use iasi2cris.m in iasi_decon
% $$$ addpath /asl/packages/iasi_decon
% $$$ addpath /asl/packages/ccast/source
addpath /home/sbuczko1/git/rtp_prod2/cris
addpath /home/sbuczko1/git/rtp_prod2/util
addpath /home/sbuczko1/git/rtp_prod2/emis
addpath /home/sbuczko1/git/rtp_prod2/grib

% $$$ % print out path to compare to interacive session
% $$$ fid = fopen('~/pathtest/hpcstartpath.txt', 'wt');
% $$$ startpath=strsplit(path(), ':');
% $$$ [nrows, ncols] = size(startpath);
% $$$ for i=1:ncols
% $$$     fprintf(fid, '%s\n', startpath{i});
% $$$ end
% $$$ fclose(fid);
% $$$ % end path check

[sID, sTempPath] = genscratchpath();

sID = getenv('SLURM_ARRAY_TASK_ID')

nguard = 2;  % number of guard channels

fprintf(1, '>> %s Running create_cris_ccast_lowres_day_rtp for input: %s\n', ...
        char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);

% fnCrisInput is a path of the form:
% /asl/data/cris/ccast/sdr60/YYYY/DOY
% output will go to /asl/data/rtp_cris_ccast_lowres/YYYY
pathparts = strsplit(fnCrisInput, '/');
% lustre file paths can have two forms with different number of
% components but, year is always the second to last
cris_yearstr=pathparts{end-1};

% generate a list of the mat files in the the day pointed to by
% fnCrisInput
% We don't need file metadata so, here, use ls(). Pass
% '-1' to system to make an easily parsable string (elements
% separated by \n newline, strip trailing spaces and split
fnLst1 = dir(fullfile(fnCrisInput, 'SDR_d*.mat')); 
numgrans = numel(fnLst1);
if numgrans ~= 0
    fprintf(1,'>>> %s Found %d granule files to process\n', ...
            char(datetime('now', 'Format', 'HHmmss')), numel(fnLst1));
else
    fprintf(2, ['>>> %s ERROR: No granules files found for day %s. ' ...
                'Exiting.\n'], char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);
    return;
end


% Load up first rtp so we have something to concatenate onto
try
    [h, ha, p, pa] = ccast2rtp(fullfile(fnCrisInput,fnLst1(1).name), nguard);
catch
    fprintf(2, '>>> %s ERROR: ccast2rtp failure (block one).\n', char(datetime('now', 'Format', 'HHmmss')));
    return;
end
temp = size(h.ichan)
if temp(2) > 1
    h.ichan = h.ichan';
end
temp = size(h.vchan)
if temp(2) > 1
    h.vchan = h.vchan';
end

% get strut definition and fields before subsetting (just in case
% first granule has no obs after random subset
pf = fieldnames(p);
m = length(pf);

% build random subset and then subset the profile struct
npresub = numel(p.rlat);
[irand,irand2] = hha_lat_subsample_equal_area2_cris_hires(h, p);
p = rtp_sub_prof(p,irand);
npostsub = numel(p.rlat);
fprintf(1, ['>>> %s First granule obs count: pre-sub = %d\tpost-sub = ' ...
            '%d\n'], char(datetime('now', 'Format', 'HHmmss')), npresub, npostsub);

for i=2:numel(fnLst1)
    % incrementally build out the concatenated profile struct as we
    % read in new granule files. This is inefficient but, should do
    % the trick for now.
    p1 = p; 
    try
        [h2, ha2, p2, pa2] = ccast2rtp(fullfile(fnCrisInput,fnLst1(i).name), nguard);
    catch
        fprintf(2, ['>>> %s ERROR: ccast2rtp failure (block two). Trying ' ...
                    'next granule\n'], char(datetime('now', 'Format', 'HHmmss')));
        continue;
    end

    % build random subset and then subset the profile struct    
    npresub = numel(p2.rlat);
    try
        [irand,irand2] = hha_lat_subsample_equal_area2_cris_hires(h2, ...
                                                          p2);
    catch
        fprintf(2, ['>>> %s ERROR: hha_lat_sub... failure in granule ' ...
                    '%s\n'], char(datetime('now', 'Format', 'HHmmss')), ...
                fullfile(fnCrisInput, fnLst1(i).name));
        continue;
    end
    
    p2 = rtp_sub_prof(p2,irand);
    npostsub = numel(p2.rlat);
    fprintf(1, ['>>> %s Granule obs count: pre-sub = %d\tpost-sub = ' ...
                '%d\n'], char(datetime('now', 'Format', 'HHmmss')), npresub, npostsub);

    % concatenate rtp structures (this is the guts of
    % cat_rtp_dir.m)
    ns1 = size(p1.rlat);
    ns2 = size(p2.rlat);
    n(1) = ns1(2);
    n(2) = ns2(2);
    i2 = cumsum(n);
    i1 = i2 - n + 1;
    ntot = sum(n);
    
    % Actual allocation
    for j=1:m
        [r c] = size(p1.(pf{j}));
        dtype = class(p1.(pf{j}));
        p.(pf{j}) = zeros(r,ntot,dtype);
    end
    
    % Now fill arrays, looping over files and fieldnames
    for j=1:m
        p.(pf{j})(:,i1(1):i2(1)) = p1.(pf{j});
        p.(pf{j})(:,i1(2):i2(2)) = p2.(pf{j});
    end
    clear p1, p2;
    
end  % end loop over mat files
    

% Need this later
ichan_ccast = h.ichan;

% Add profile data
fprintf(1, '>>> %s Running fill_era...\n', char(datetime('now', 'Format', 'HHmmss')));
[p,h]=fill_era(p,h);
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));
h.pfields = 5;
[nchan,nobs] = size(p.robs1);
h.nchan = nchan;
h.ngas=2;


% Add landfrac, etc.
fprintf(1, '>>> %s Running usgs_10dem...\n',char(datetime('now', 'Format', 'HHmmss')));
[h, ha, p, pa] = rtpadd_usgs_10dem(h,ha,p, pa);
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% Add Dan Zhou's emissivity and Masuda emis over ocean
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> %s Running add_emis...\n',char(datetime('now', 'Format', 'HHmmss')));
[p,pa] = rtp_add_emis_single(p,pa);
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% run klayers
fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
rtpwrite(fn_rtp1,h,ha,p,pa)
fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);

fprintf(1, '>>> %s Running klayers...\n', char(datetime('now', 'Format', 'HHmmss')));
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath ...
               '/klayers_' sID '_stdout']
try
    unix(klayers_run);
catch
    fprintf(2, '>>> %s ERROR: klayers failed for day %s\n', ...
            char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);
    return;
end
fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));

fprintf(1, '>>> %s Reading in klayers output...\n', char(datetime('now', 'Format', 'HHmmss')));
[h, ha, p, pa] = rtpread(fn_rtp2);
fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));

% Run sarta
fprintf(1, '>>> %s Running sarta...\n', char(datetime('now', 'Format', 'HHmmss')));
fn_rtp3 = fullfile(sTempPath, ['cris_' sID '_3.rtp']);
sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ' > ' ...
             sTempPath '/sarta_' sID '_stdout']
try
    unix(sarta_run);
catch
    fprintf(2, '>>> %s ERROR: sarta failed for day %s\n', ...
            char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);
    return;
end
fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));

% $$$ % print out path to compare to interacive session
% $$$ fid = fopen('~/pathtest/hpcendpath.txt', 'wt');
% $$$ endpath=strsplit(path(), ':');
% $$$ [nrows, ncols] = size(endpath);
% $$$ for i=1:ncols
% $$$     fprintf(fid, '%s\n', endpath{i});
% $$$ end
% $$$ fclose(fid);
% $$$ % end path check

% Read in new rcalcs and insert into origin prof field
fprintf(1, '>>> %s Reading in sarta output...\n', char(datetime('now', 'Format', 'HHmmss')));
[h2,ha2,p2,pa2] = rtpread(fn_rtp3);
fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));

% Insert rcalc for CrIS derived from IASI SARTA
fprintf(1, '>>> %s Substituting rcalc values into klayers output...\n', ...
        char(datetime('now', 'Format', 'HHmmss')));
p.rcalc = p2.rcalc;
h.pfields = 7;
fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));

% Make directory if needed
% cris lowres data will be stored in
% /asl/data/rtp_cris_ccast_lowres/{clear,dcc,site,random}/<year>/<doy>
%
asType = {'random'};
cris_out_dir = '/asl/data/rtp_cris_ccast_lowres';
%cris_out_dir = '/strow_temp/sbuczko1/testoutput/rtp_cris_ccast_lowres';
for i = 1:length(asType)
    % check for existence of output path and create it if necessary. This may become a source
    % for filesystem collisions once we are running under slurm.
    sPath = fullfile(cris_out_dir,char(asType(i)),cris_yearstr);
    if exist(sPath) == 0
        mkdir(sPath);
    end
end
% $$$
% build output filename based on date stamp of input mat files
parts = strsplit(fnLst1(1).name, '_');
cris_datestr = parts{2};
rtp_out_fn = ['rtp_' cris_datestr '_rand.rtp'];

% Now save the four types of cris files
nobs = numel(p.rlat);
rtp_outname = fullfile(sPath, rtp_out_fn);
fprintf(1, '>>> %s writing %d profiles to output rtp file\n\t%s ... ', ...
        char(datetime('now', 'Format', 'HHmmss')), nobs, rtp_outname);
rtpwrite(rtp_outname,h,ha,p,pa);
fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));


% Next delete temporary files
delete(fn_rtp1);delete(fn_rtp2)
