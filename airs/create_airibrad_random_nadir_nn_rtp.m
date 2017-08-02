function create_airibrad_random_nadir_nn_rtp(inpath, cfg)
%
% NAME
%   create_airibrad_rtp -- wrapper to process AIRIBRAD to RTP
%
% SYNOPSIS
%   create_airibrad_rtp(infile, cfg)
%
% INPUTS
%    infile :   path to input AIRIBRAD hdf file
%    cfg :  structure of configuration options to overide defaults
%
% L. Strow, Jan. 14, 2015
%
% DISCUSSION (TBD)
func_name = 'create_airibrad_random_nadir_rtp';

% set some defaults
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = ['/asl/packages/sartaV108/BinV201/' ...
                'sarta_apr08_m140_wcon_nte'];
model = 'era';
chanID = 764; % match to CrIS chanID 404
outfile_head = '/asl/rtp/rtp_airibrad_v5/';

if nargin == 2 % cfg structure present to overide defaults
    if isfield(cfg, 'klayers_exec')
        klayers_exec = cfg.klayers_exec;
    end
    if isfield(cfg, 'sarta_exec')
        sarta_exec = cfg.sarta_exec;
    end
    if isfield(cfg, 'model')
        model = cfg.model;
    end
    if isfield(cfg, 'chanID')
        chanID = cfg.chanID;
    end
    if isfield(cfg, 'outfile_head')
        outfile_head = cfg.outfile_head;
    end
end

addpath('/home/sbuczko1/git/swutils');
trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

% Execute user-defined paths
addpath /home/sbuczko1/git/rtp_prod2/airs   % new equal_area random
                                            % code
addpath('/asl/matlib/rtptools');   % for cat_rtp
addpath /asl/matlib/aslutil   % int2bits


% build output filename
% assumes path is like: /asl/data/airs/AIRIBRAD/<year>/<doy>
C = strsplit(inpath, '/');
sYear = C{6};
sDoy = C{7};
fname = sprintf('%s_airibrad_day%s_random-smear-chan%d.rtp', model, sDoy, ...
                chanID);
outfile_path = fullfile(outfile_head, sYear, 'random');
if ~exist(outfile_path)
    mkdir(outfile_path);
end
outfile = fullfile(outfile_path, fname);

% $$$ if exist(outfile_path) ~= 0
% $$$     fprintf(1, ['>>> Output file exists from previous run. Skipping\' ...
% $$$                 'n']);
% $$$     return;
% $$$ end

% This version operates on a day of AIRIBRAD granules and
% concatenates the subset of random obs into a single output file
% >> inpath is the path to an AIRS day of data
% /asl/data/airs/AIRIBRAD/<year>/<doy>
files = dir(fullfile(inpath, '*.hdf'));

for i=1:length(files)
    % Read the AIRIBRAD file
    infile = fullfile(inpath, files(i).name);
    fprintf(1, '>>> Reading input file: %s   ', infile);
    try
        [eq_x_tai, freq, p, pattr] = read_airibrad(infile);
    catch
        fprintf(2, ['>>> ERROR: failure in read_airibrad for granule %s. ' ...
                    'Skipping.\n'], infile);
        continue;
    end
    fprintf(1, 'Done\n');

    % only need one chan, so just pull that out now to save space
    p.robs1 = p.robs1(chanID,:);
    p.calflag = p.calflag(chanID,:);
    
    % filter out nadir FOVs (45&46  (+ neighbors))
    fovs = [45 46];
    nadir = ismember(p.xtrack,fovs);
    limit = 0.011*44;  % preserves ~20k obs/day
    randoms = get_equal_area_sub_indices(p.rlat, limit);
    nrinds = find(nadir & randoms);
    crprof = rtp_sub_prof(p, nrinds);
    crprof.robs1 = [crprof.robs1(1,:)' p.robs1(1,nrinds-1)' ...
                    p.robs1(1,nrinds+1)']';
    crprof.calflag = [crprof.calflag(1,:)' p.calflag(1,nrinds-1)' ...
                      p.calflag(1,nrinds+1)']';
    p=crprof;
    clear crprof;

    if ~exist('head') % only need to build the head structure once but, we do
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
        chani = repmat(chanID, 3, 1);
        vchan = freq;

        % Assign header variables
        head.instid = 800; % AIRS 
        head.pltfid = -9999;
        head.nchan = length(chani);
        head.ichan = chani;
        head.vchan = vchan(chani);
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
% $$$ if (~SKIP)
% Add in model data
fprintf(1, '>>> Add model: %s...', model)
switch model
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

% $$$ % call klayers/sarta cloudy
% $$$ run_sarta.cloud=+1;
% $$$ run_sarta.clear=+1;
% $$$ run_sarta.cumsum=-1;
% $$$ % driver_sarta_cloud_rtp ultimately looks for default sarta
% $$$ % executables in Sergio's directories. **DANGEROUS** These need to
% $$$ % be brought under separate control for traceability purposes.
% $$$ % $$$ try
% $$$     [prof0, oslabs] = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);
% $$$ % $$$ catch
% $$$ % $$$     fprintf(2, ['>>> ERROR: failure in driver_sarta_cloud_rtp for ' ...
% $$$ % $$$                 '%s/%s\n'], sYear, sDoy);
% $$$ % $$$     return;
% $$$ % $$$ end
% $$$ end  % end if (~SKIP)

% profile attribute changes for airibrad
pa = set_attr('profiles', 'robs1', infile);
pa = set_attr(pattr, 'rtime', 'TAI:1958');

% Now save the output random rtp file
fprintf(1, '>>> writing output rtp files... ');
try
    rtpwrite(outfile, head, hattr, prof, pattr);
catch
    fprintf(2, '>>> ERROR: rtpwrite failure for %s/%s\n', sYear, ...
            sDoy);
    return;
end

fprintf(1, 'Done\n');

            
