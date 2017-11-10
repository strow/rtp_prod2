function create_airicrad_random_nadir_rtp(inpath, outfile_head, cfg)
%
% NAME
%   create_airicrad_rtp -- wrapper to process AIRICRAD to RTP
%
% SYNOPSIS
%   create_airicrad_rtp(infile, outfile_head)
%
% INPUTS
%    infile :   path to input AIRICRAD hdf file
%    outfile_head  : path to output rtp file (minus extension)
%
% L. Strow, Jan. 14, 2015
%
% DISCUSSION (TBD)
func_name = 'create_airicrad_random_nadir_rtp';

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';

addpath('/home/sbuczko1/git/swutils');
trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

% Execute user-defined paths
set_process_dirs
addpath(genpath(rtp_sw_dir));
% $$$ addpath('/home/sergio/MATLABCODE/PLOTTER');  % for hha_lat_subsample_equal_area3
addpath('/asl/matlib/rtptools');   % for cat_rtp
% $$$ addpath(genpath('/home/sergio/MATLABCODE/matlib/'));  %
                                                      % driver_sarta_cloud_rtp.m
addpath(genpath('/home/sbuczko1/git/matlib/'));  % driver_sarta_cloud_rtp.m

% build output filename
% assumes path is like: /asl/data/airs/AIRICRAD/<year>/<doy>
C = strsplit(inpath, '/');
sYear = C{6};
sDoy = C{7};
outfile_base = fullfile(outfile_head, sYear, 'random');
if exist(outfile_base) == 0
    status = mkdir(outfile_base);
end
outfile_path = fullfile(outfile_base, ...
                        sprintf('%s_airicrad_day%s_random.rtp', ...
                                cfg.model, sDoy));

% $$$ if exist(outfile_path) ~= 0
% $$$     fprintf(1, ['>>> Output file exists from previous run. Skipping\' ...
% $$$                 'n']);
% $$$     return;
% $$$ end

load /home/sbuczko1/git/rtp_prod2/airs/util/sarta_chans_for_l1c.mat

% This version operates on a day of AIRICRAD granules and
% concatenates the subset of random obs into a single output file
% >> inpath is the path to an AIRS day of data
% /asl/data/airs/AIRICRAD/<year>/<doy>
files = dir(fullfile(inpath, '*.hdf'));

for i=1:length(files)
    % Read the AIRICRAD file
    infile = fullfile(inpath, files(i).name);
    fprintf(1, '>>> Reading input file: %s   ', infile);
    try
        [eq_x_tai, freq, p, pattr] = read_airicrad(infile);
    catch
        fprintf(2, ['>>> ERROR: failure in read_airicrad for granule %s. ' ...
                    'Skipping.\n'], infile);
        continue;
    end
    fprintf(1, 'Done\n');

        
    % filter out desired FOVs/scan angles 
    fovs = [43:48];  % [45 46] original, [43:48] current nadir,
                     % [1:90]  full swath
    nadir = ismember(p.xtrack,fovs);
    % rtp has a 2GB limit so we have to scale number of kept FOVs
    % to stay within that as an absolute limit. Further, we
    % currently restrict obs count in random to ~20k to match
    % historical AIRXBCAL processing
    limit = 20000;  % number of obs to keep
    maxobs = 135 * length(fovs) * 240;
    scale = (limit/maxobs)*1.6; % preserves ~20k obs/day (without
                                % 1.6 multiplier, only getting
                                % ~12-13k counts ?? 
    randoms = get_equal_area_sub_indices(p.rlat, scale);
    nrinds = find(nadir & randoms);
    crprof = rtp_sub_prof(p, nrinds);
    p=crprof;
    clear crprof;

    if i == 1 % only need to build the head structure once but, we do
              % need freq data read in from first data file
              % Header 
        head = struct;
        head.pfields = 4;  % robs1, no calcs in file
        head.ptype = 0;    
        head.ngas = 0;

        % Assign header attribute strings
        hattr={ {'header' 'pltfid' 'Aqua'}, ...
                {'header' 'instid' 'AIRS'}, ...
                {'header' 'githash' trace.githash}, ...
                {'header' 'rundate' trace.RunDate}, ...
                {'header' 'klayers_exec' klayers_exec}, ...
                {'header' 'sarta_exec' sarta_exec} };

        nchan = size(p.robs1,1);
        %vchan = aux.nominal_freq(:);
        vchan = freq;

        % Assign header variables
        head.instid = 800; % AIRS 
        head.pltfid = -9999;
        head.nchan = length(ichan);
        head.ichan = ichan;
        head.vchan = vchan;
        head.vcmax = max(head.vchan);
        head.vcmin = min(head.vchan);
    end  % end if i == 1
        
        % concatenate rtp structs
        if ~exist('prof')
            prof = p;
        else
            [head, prof] = cat_rtp(head, prof, head, p);
        end

end  % end for i=1:length(files)

% Fix for zobs altitude units
if isfield(prof,'zobs')
   iz = prof.zobs < 20000 & prof.zobs > 20;
   prof.zobs(iz) = prof.zobs(iz) * 1000;
end

SKIP=0;
if (~SKIP)
% Add in model data
fprintf(1, '>>> Add model: %s...', cfg.model)
switch cfg.model
  case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
  case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
end
head.pfields = 5;
fprintf(1, 'Done\n');

% Dan Zhou's one-year climatology for land surface emissivity and
% standard routine for sea surface emissivity
fprintf(1, '>>> Running rtp_add_emis...');
try
    [prof,pattr] = rtp_add_emis(prof,pattr);
catch
    fprintf(2, '>>> ERROR: rtp_add_emis failure for %s/%s\n', sYear, ...
            sDoy);
    return;
end
fprintf(1, 'Done\n');

% call klayers/sarta cloudy
run_sarta.cloud=+1;
run_sarta.clear=+1;
run_sarta.cumsum=-1;
% driver_sarta_cloud_rtp ultimately looks for default sarta
% executables in Sergio's directories. **DANGEROUS** These need to
% be brought under separate control for traceability purposes.
% $$$ try
    [prof0, oslabs] = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);
% $$$ catch
% $$$     fprintf(2, ['>>> ERROR: failure in driver_sarta_cloud_rtp for ' ...
% $$$                 '%s/%s\n'], sYear, sDoy);
% $$$     return;
% $$$ end
end  % end if (~SKIP)

% profile attribute changes for airicrad
pa = set_attr('profiles', 'robs1', infile);
pa = set_attr(pa, 'rtime', 'TAI:1958');

% Now save the output random rtp file
fprintf(1, '>>> writing output rtp files... ');

rtpwrite(outfile_path, head, hattr, prof0, pa);

% $$$ try
% $$$     rtpwrite(outfile_path, head, hattr, prof0, pa);
% $$$ catch
% $$$     fprintf(2, '>>> ERROR: rtpwrite failure for %s/%s\n', sYear, ...
% $$$             sDoy);
% $$$     return;
% $$$ end

fprintf(1, 'Done\n');

            
