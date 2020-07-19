function create_cris_ccast_lowres_day_rtp(fnCrisInput, cfg)
% PROCESS_CRIS_LOWRES process one day's worth of granules of CrIS data
% concatenate each granule into a single daily rtp file and subset
% for random

% read in mat files found in a single day of CRiS SDR60 files
% produced at UMBC by Howard Motteler. As each granule is read in,
% find the required subset (clear, dcc, site) and concatenate to a
% running structure of subset obs. once a day of granules is
% assembled, run klayers and sarta and output rtp.

% Current directory structure puts CRiS sdr granule data under:
% /asl/data/cris/ccast/sdr60/<YYYY>/<DOY>

% Current granule filenaming convention under the directories
% above:


addpath /home/sbuczko1/git/ccast/motmsc/rtp_sarta  % ccast2rtp
addpath /asl/matlib/rtptools  % cat_rtp.m
addpath /asl/matlib/aslutil   % int2bits
addpath /asl/packages/time    % iet2tai (in ccast2rtp)
addpath /home/sbuczko1/git/rtp_prod2_DEV/cris
addpath /asl/packages/rtp_prod2_DEV/util
addpath /asl/packages/rtp_prod2_DEV/emis
addpath /asl/packages/rtp_prod2_DEV/grib

[sID, sTempPath] = genscratchpath();
sID = getenv('SLURM_ARRAY_TASK_ID')

% set defaults
nguard = 2;  % number of guard channels
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
               'sarta_crisg4_nov09_wcon_nte'];  %% lowres
model = 'era'; % ERA-Interim

% read in configuration (if present) and modify defaults
if nargin == 2   % config structure present
    if isfield(cfg, 'nguard')
        nguard = cfg.nguard;
    end
    if isfield(cfg, 'klayers_exec')
        klayers_exec = cfg.klayers_exec;
    end
    if isfield(cfg, 'sarta_exec')
        sarta_exec = cfg.sarta_exec;
    end
    if isfield(cfg, 'model')
        model = cfg.model;
    end
end

fprintf(1, '>> %s Running create_cris_ccast_lowres_day_rtp for input: %s\n', ...
        char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);

% fnCrisInput is a path of the form:
% /asl/data/cris/ccast/sdr60/YYYY/DOY
% output will go to /asl/rtp/rtp_cris_ccast_lowres/YYYY
pathparts = strsplit(fnCrisInput, '/');
cris_yearstr=pathparts{end-1};  % grab YYYY from input path, needed
                                % for output path

% generate a list of the mat files in the the day pointed to by
% fnCrisInput
fnLst1 = dir(fullfile(fnCrisInput, 'SDR_d*_t*.mat')); 
numgrans = numel(fnLst1);
if numgrans ~= 0
    fprintf(1,'>>> %s Found %d granule files to process\n', ...
            char(datetime('now', 'Format', 'HHmmss')), numel(fnLst1));
else
    fprintf(2, ['>>> %s ERROR: No granules files found for day %s. ' ...
                'Exiting.\n'], char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);
    return;
end

bFirstGranRead = false;
for i=1:numel(fnLst1)
    % try reading the granule files and concatenate profiles for
    % each granule read
    try
        [h2, ha2, p2, pa2] = ccast2rtp(fullfile(fnCrisInput,fnLst1(i).name), nguard);
    catch
        fprintf(2, ['>>> %s ERROR: ccast2rtp failure. Trying ' ...
                    'next granule\n'], char(datetime('now', 'Format', 'HHmmss')));
        continue;
    end

    % ensure that we have column vectors in head
    temp = size(h2.ichan);
    if temp(2) > 1
        h2.ichan = h2.ichan';
    end
    temp = size(h2.vchan); 
    if temp(2) > 1
        h2.vchan = h2.vchan';
    end

    % sarta puts limits on satzen/satang (satzen comes out in the
    % profiles form ccast2rtp) so, filter to remove profiles
    % outside this range to keep sarta from failing.
    inrange = find(p2.satzen >= 0.0 & p2.satzen < 63.0);
    p2 = rtp_sub_prof(p2, inrange);
% $$$     cobs = aux.cobs1(:,inrange);
% $$$     aux.cobs1 = cobs;
% $$$     clear cobs inrange;
    clear inrange;
    
    % Add profile data
    fprintf(1, '>>> %s Running fill_era...\n', char(datetime('now', 'Format', 'HHmmss')));
    [p2,h2, pa2]=fill_era(p2,h2, pa2);
    fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));
    h2.pfields = 5;
    [nchan,nobs] = size(p2.robs1);
    h2.nchan = nchan;
    h2.ngas=2;
    
    % Add landfrac, etc.
    fprintf(1, '>>> %s Running usgs_10dem...\n',char(datetime('now', 'Format', 'HHmmss')));
    [h2, ha2, p2, pa2] = rtpadd_usgs_10dem(h2,ha2,p2, pa2);
    fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

    % Add Dan Zhou's emissivity and Masuda emis over ocean
    % Dan Zhou's one-year climatology for land surface emissivity and
    % standard routine for sea surface emissivity
    fprintf(1, '>>> %s Running add_emis...\n',char(datetime('now', 'Format', 'HHmmss')));
    [p2,pa2] = rtp_add_emis_single(p2,pa2);
    fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

    % run klayers
    fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
    rtpwrite(fn_rtp1,h2,ha2,p2,pa2)
    fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);

    fprintf(1, '>>> %s Running klayers...\n', char(datetime('now', 'Format', 'HHmmss')));
    klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath ...
                   '/klayers_' sID '_stdout'];
    try
        unix(klayers_run);
    catch
        fprintf(2, '>>> %s ERROR: klayers failed for day %s\n', ...
                char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);
        return;
    end
    fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));

    % Run sarta
    fprintf(1, '>>> %s Running sarta...\n', char(datetime('now', 'Format', 'HHmmss')));
    fn_rtp3 = fullfile(sTempPath, ['cris_' sID '_3.rtp']);
    sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ' > ' ...
                 sTempPath '/sarta_' sID '_stdout'];
    try
        unix(sarta_run);
    catch
        fprintf(2, '>>> %s ERROR: sarta failed for day %s\n', ...
                char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);
        return;
    end
    fprintf(1, '>>> %s Reading in sarta output...\n', char(datetime('now', 'Format', 'HHmmss')));
    [h2, ha2, p2, pa2] = rtpread(fn_rtp3);
    fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));

    rcalcs = p2.rcalc;  % save for later insertion back into rtp
    
    % make subset assignments (all subsets are assigned here but
    % site/dcc/random need to be treated to another round of sarta
    % for cloudy calcs) ( can we do this all in one by running
    % cloudy calcs on even clears?)
    npresub = numel(p2.rlat);
    try
        [p_tmp, ikeep] = uniform_clear_template_lowANDhires_HP(h2,ha2,p2,pa2); %% super (if it works)
    catch
        fprintf(2, ['>>> %s ERROR: uniform_clear_... failure in granule ' ...
                    '%s\n'], char(datetime('now', 'Format', 'HHmmss')), ...
                fullfile(fnCrisInput, fnLst1(i).name));
        continue;
    end
    iudef = p_tmp.iudef;  % save the assigned reasons
    clear p_tmp;
    
    [h2, ha2, p2, pa2] = rtpread(fn_rtp1);  % read pre-klayers rtp
    p2.rcalc = rcalcs;  % reinsert calcs
    h2.pfields = 7;  % profile + obs + calcs
    clear rcalcs;
    p2 = rtp_sub_prof(p2, ikeep);  % re-apply subsetting
    p2.iudef = iudef;  % restore assigned reasons
    clear iudef;
    
    % take clear, clear/site, and clear/random assignments
    iclear = find(p2.iudef(1,:) == 1 | p2.iudef(1,:) == 3 | ...
                  p2.iudef(1,:) == 9); 

    p2 = rtp_sub_prof(p2,iclear);
    npostsub = numel(p2.rlat);
    fprintf(1, ['>>> %s Granule obs count: pre-sub = %d\tpost-sub = ' ...
                '%d\n'], char(datetime('now', 'Format', 'HHmmss')), npresub, npostsub);

    % now that we've trimmed off many (most?) of the obs,
    % concatenate into a single daily rtp structure
    if ~bFirstGranRead % this is first good read. Take rtp structs
                       % as baseline for subsequent concatenation
        h = h2;
        ha = ha2;
        p = p2;
        pa = pa2;
% $$$         % subset complex spectra to match uniform_clear_ ... output
% $$$         cobs = aux.cobs1(:,ikeep);
% $$$         % subset again with the clears
% $$$         cobs1 = cobs(:,iclear);
% $$$         clear cobs;
        
        bFirstGranRead = true;
    else
        [h, p] = cat_rtp(h, p, h2, p2);

% $$$         % subset complex spectra to mathc uniform_clear_ ... otput
% $$$         cobs = aux.cobs1(:,ikeep);
% $$$         % subset again with the clears
% $$$         cobs1a = cobs(:,iclear);
% $$$         % concatenate onto running array
% $$$         cobs1 = cat(2, cobs1, cobs1a);
% $$$         clear cobs1a cobs;
    end
    
end  % end loop over mat files

% Make directory if needed
% cris lowres data will be stored in
% /asl/data/rtp_cris_ccast_lowres/{clear,dcc,site,random}/<year>/<doy>
%
asType = {'clear'};
cris_out_dir = '/asl/rtp/rtp_cris_ccast_lowres';
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
rtp_out_fn = ['rtp_' cris_datestr '_clear.rtp'];

% Now save the four types of cris files
nobs = numel(p.rlat);
rtp_outname = fullfile(sPath, rtp_out_fn);
fprintf(1, '>>> %s writing %d profiles to output rtp file\n\t%s ... ', ...
        char(datetime('now', 'Format', 'HHmmss')), nobs, rtp_outname);
rtpwrite(rtp_outname,h,ha2,p,pa2);
fprintf(1, '>>> %s Done\n', char(datetime('now', 'Format', 'HHmmss')));


% now save the complex spectra (in mat file associated with rtp)
% $$$ mat_out_fn = ['cspectra_' cris_datestr '_NewQA_clear.mat'];
% $$$ save(fullfile(sPath, mat_out_fn), 'cobs1');

% Next delete temporary files
delete(fn_rtp1);delete(fn_rtp2)
