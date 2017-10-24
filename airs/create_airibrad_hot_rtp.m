function create_airibrad_hot_rtp(inpath, outfile_head, cfg)
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
func_name = 'create_airibrad_hot_rtp';

% $$$ klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
% $$$ sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';

addpath('/home/sbuczko1/git/swutils');
addpath('/home/sbuczko1/git/rtp_prod2/airs/readers');
addpath('/asl/matlib/aslutil');

trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                         'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

% Execute user-defined paths
rtp_sw_dir       = '/home/sbuczko1/git/rtp_prod2';
addpath(genpath(rtp_sw_dir));
addpath('/asl/matlib/rtptools');   % for cat_rtp
addpath('/home/sbuczko1/git/rtp_prod2/util');  % for hot_scene_check

% build output filename
% assumes path is like: /asl/data/airs/AIRIBRAD/<year>/<doy>
C = strsplit(inpath, '/');
sYear = C{6};
sDoy = C{7};


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
        [eq_x_tai, freq, prof0, pattr] = read_airibrad(infile);
    catch
        fprintf(2, ['>>> ERROR: failure in read_airibrad for granule %s. ' ...
                    'Skipping.\n'], infile);
        continue;
    end
    fprintf(1, 'Done\n');

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
                {'header' 'rundate' trace.RunDate} };
        
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
    end  % end if i == 1
        
        % find hot scenes and subset out
        btthresh = 335;  % 335K BT min for inclusion
        idtest_lw = 756:759;
        idtest_sw = 2197:2224;
        ib = hot_scene_check(head, prof0, btthresh, idtest_lw, ...
                             idtest_sw);
        fprintf(1, '>>> Found %d hot scenes in %s\n', length(ib), infile);
        if (length(ib) > 0)
            p = rtp_sub_prof(prof0, ib);
        else
            continue;
        end
        clear prof0;
        
        % if hot obs were found, stuff them into daily
        % rtp. Otherwise, next granule
        if (~exist('prof'))
            prof = p;
            clear p;
        else
            prof1 = prof;
            % concatenate new random rtp data into running random rtp structure
            [head, prof] = cat_rtp(head, prof1, head, p);
            clear prof1;
        end

end  % end for i=1:length(files)

    % quick sanity check on existence of prof struct and profiles
    % inside
    if (~exist('prof'))
        fprintf(2, '*** No hot obs found for %s/%s\n', sYear, ...
                sDoy);
        return;
    else
        fprintf(1, '>>> Found %d hot scenes for day %s/%s\n', ...
                length(prof.rtime), sYear, sDoy);
    end

% Fix for zobs altitude units
if isfield(prof,'zobs')
   iz = prof.zobs < 20000 & prof.zobs > 20;
   prof.zobs(iz) = prof.zobs(iz) * 1000;
end

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
% check that we have same number of model entries as we do obs because
% corrupt model files will leave us with an unbalanced rtp
% structure which WILL fail downstream (ideally, this should be
% checked for in the fill_* routines but, this is faster for now)
[~,nobs] = size(prof.robs1);
[~,mobs] = size(prof.gas_1);
if mobs ~= nobs
    fprintf(2, ['*** ERROR: number of model entries does not agree ' ...
                'with nobs ***\n'])
    return;
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

% profile attribute changes for airibrad
pa = set_attr('profiles', 'robs1', infile);
pa = set_attr(pa, 'rtime', 'TAI:1958');

% Now save the output random rtp file
% Make directory if needed
sPath = fullfile(outfile_head,char(cfg.type),sYear);
if exist(sPath) == 0
    mkdir(sPath);
end
outfile_path = fullfile(sPath, [cfg.model '_airibrad_day' ...
                    sDoy '_hot.rtp']);

fprintf(1, '>>> writing output rtp files... ');
try
    rtpwrite(outfile_path, head, hattr, prof, pa);
catch
    fprintf(2, '>>> ERROR: rtpwrite failure for %s/%s\n', sYear, ...
            sDoy);
    return;
end

fprintf(1, 'Done\n');

            
