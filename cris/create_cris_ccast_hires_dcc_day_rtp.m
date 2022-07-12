function [head, hattr, prof, pattr] = create_cris_ccast_hires_dcc_day_rtp(fnCrisInput, cfg)
% CREATE_CRIS_CCAST_LOWRES_DCC_DAY_RTP process one day's worth of granules of CrIS data
% concatenate each granule into a single daily rtp file and subset
% for dcc

% read in mat files found in a single day of CRiS SDR60 files
% produced at UMBC by Howard Motteler. As each granule is read in,
% find the dcc subset and concatenate to a
% running structure of subset obs. once a day of granules is
% assembled, run klayers and sarta and output rtp.

% Current directory structure puts CRiS sdr granule data under:
% /asl/cris/ccast/sdr45_npp_HR/YYYY/DOY

% Current granule filenaming convention under the directories
% above:
func_name = 'create_cris_ccast_hires_dcc_day_rtp';

[status, trace.githash] = githash();
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

[sID, sTempPath] = genscratchpath();
sID = getenv('SLURM_ARRAY_TASK_ID')

fprintf(1, '>> %s Running create_cris_ccast_hires_dcc_day_rtp for input: %s\n', ...
        char(datetime('now', 'Format', 'HHmmss')), fnCrisInput);

% fnCrisInput is a path of the form:
% /asl/data/cris/ccast/sdr60/YYYY/DOY
% output will go to /asl/rtp/rtp_cris_ccast_lowres/YYYY
pathparts = strsplit(fnCrisInput, '/');
cris_yearstr=pathparts{end-1};  % grab YYYY from input path, needed
                                % for output path

% generate a list of the mat files in the the day pointed to by
% fnCrisInput
fnLst1 = dir(fullfile(fnCrisInput, cfg.fnamestr)); 
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

prof = struct([]);
head = struct([]);
pattr = {}; hattr={};

filestride=1; % default is to read every granule
if isfield(cfg, 'filestride')
    filestride = cfg.filestride;  % cfg overrides stride for faster
                                  % testing
end
for i=1:filestride:length(fnLst1)
    % try reading the granule files and concatenate profiles for
    % each granule read
    fprintf(1, '>>> Granule %d\n', i);
% $$$     try
        [h, ha, p, pa] = ccast2rtp(fullfile(fnLst1(i).folder,fnLst1(i).name), cfg.nguard);
% $$$     catch
% $$$         fprintf(2, ['>>> %s ERROR: ccast2rtp failure. Trying ' ...
% $$$                     'next granule\n'], char(datetime('now', 'Format', 'HHmmss')));
% $$$         continue;
% $$$     end

    % ensure that we have column vectors in h
    temp = size(h.ichan);
    if temp(2) > 1
        h.ichan = h.ichan';
    end
    temp = size(h.vchan); 
    if temp(2) > 1
        h.vchan = h.vchan';
    end

    % sarta puts limits on satzen/satang (satzen comes out in the
    % profiles form ccast2rtp) so, filter to remove profiles
    % outside this range to keep sarta from failing.
    insatzenrange = (p.satzen >= 0.0 & p.satzen < 63.0);
    inlatrange = (abs(p.rlat) <= cfg.latmaxhicloud);  
    keep_ind = find(insatzenrange & inlatrange);
    if 0 == length(keep_ind)  
        % no obs in latitude range. Next granule
        fprintf(1, ['>> No obs survive satzen/lat range filter. Next ' ...
                    'granule.\n']);
        continue;
    end
    p2 = rtp_sub_prof(p, keep_ind);
    p=p2;
    clear p2 insatzenrange inlatrange keep_ind;

    % filter out desired FOVs/scan angles
    indtest = cfg.indtest; % h.vchan indices for the 820,960, and
                            % 1231 cm-1 lines in ccast lowres
    ftest = h.vchan(indtest);
    r = p.robs1(indtest,:);
    ibad = find(r < 1E-6);
    r(ibad)=1E-6;
    mbt = mean(rad2bt(ftest,r)); % [1 x nobs]

    dcc_ind = find(mbt <= cfg.btmaxhicloud);
    if 0 == length(dcc_ind)  
        % no obs in latitude range. Next granule
        fprintf(1, ['>> No obs survive dcc filter. Next ' ...
                    'granule.\n']);
        continue;
    else
        fprintf(1, '>> %d dcc obs found in granule.\n', ...
                length(dcc_ind));
    end
    
    p2 = rtp_sub_prof(p, dcc_ind);
    p = p2;
    nobs = length(p.rtime);
    clear r ftest p2 dcc_ind mbt ibad

    % concatenate into a single daily rtp structure
    if ~bFirstGranRead % this is first good read. Take rtp structs
                       % as baseline for subsequent concatenation
        head = h;
        hattr = ha;
        prof = p;
        pattr = pa;
        
        bFirstGranRead = true;
    else
        [head, prof] = cat_rtp(head, prof, h, p);

    end
    
end  % end loop over mat files

if isempty(prof)
    fprintf(1, '*** No dcc obs found for day\n');
    return
end

fprintf(1, '>>> Found %d dcc obs\n', ...
        length(prof.rtime));
    
% Add profile data
fprintf(1, '>>> Add model: %s...', cfg.model)
switch cfg.model
  case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
  case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
end
% rtp now has profile and obs data ==> 5
head.pfields = 5;
[nchan,nobs] = size(prof.robs1);
head.nchan = nchan;
head.ngas=2;
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% Add landfrac, etc.
fprintf(1, '>>> %s Running usgs_10dem...\n',char(datetime('now', 'Format', 'HHmmss')));
[head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof, pattr);
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% Add Dan Zhou's emissivity and Masuda emis over ocean
% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> %s Running add_emis...\n',char(datetime('now', 'Format', 'HHmmss')));
[prof,pattr] = rtp_add_emis_single(prof,pattr);
fprintf(1, '>>> %s Done\n',char(datetime('now', 'Format', 'HHmmss')));

% run klayers
MAXOBS = 60000;
if length(prof.rtime) > MAXOBS
    prof = rtp_sub_prof(prof, randperm(length(prof.rtime), MAXOBS));
end

fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr);
fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
unix([cfg.klayers_exec ' fing=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath '/klayers_stdout'])

% scale gas concentrations, if requested in config
if isfield(cfg, 'scaleco2') | isfield(cfg, 'scalech4')
    % read in klayers output
    [h,ha,p,pa] = rtpread(fn_rtp2);
    delete fn_rtp2
    if isfield(cfg, 'scaleco2')
        p.gas_2 = p.gas_2 * cfg.scaleco2;
        pattr{end+1} = {'profiles' 'scaleCO2' sprintf('%f', cfg.scaleco2)};
    end
    if isfield(cfg, 'scalech4')
        p.gas_6 = p.gas_6 * cfg.scalech4;
        pattr{end+1} = {'profiles' 'scaleCH4' sprintf('%f', cfg.scalech4)};        
    end
    rtpwrite(fn_rtp2,h,ha,p,pa)
end

% run sarta

if strcmp('csarta', cfg.rta)
    fprintf(1, '>>> Running CrIS sarta... ');
    fn_rtp3 = fullfile(sTempPath, ['cris_' sID '_3.rtp']);
    sarta_run = [cfg.sartaclr_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
                 ' > ' sTempPath '/sartaout.txt'];
    unix(sarta_run);

    % read in sarta results to capture rcalc
    % *NOTE* this overwrites head,hattr,& pattr saved prior to
    % klayers to preserve any klayers/sarta-added attributes
    [head,hattr,p,pattr] = rtpread(fn_rtp3);
    prof.rclr = p.rcalc;
    clear p;
    fprintf(1, 'Done\n');
else if strcmp('isarta', cfg.rta)
        fprintf(1, '>>> Running IASI sarta... ');
        cfg.fn_rtp2 = fn_rtp2;
        [hh,hha,pp,ppa] = rtpread(fn_rtp2);
        [~, ~, p, ~] = run_sarta_iasi(hh,hha,pp,ppa,cfg);
        prof.rclr = p.rclr;
        fprintf(1, 'Done\n');
end
end  % end run sarta 

% $$$ 
% $$$     % run driver_sarta_cloud to handle klayers and sarta runs
% $$$     run_sarta.clear=+1;
% $$$     run_sarta.cloud=+1;
% $$$     run_sarta.cumsum=+9999;
% $$$     run_sarta.klayers_code = klayers_exec;
% $$$     run_sarta.sartaclear_code = sarta_exec;
% $$$     run_sarta.sartacloud_code = sartacld_exec;
% $$$ 
% $$$     prof = driver_sarta_cloud_rtp(head, hattr, prof, pattr, ...
% $$$                                   run_sarta);




