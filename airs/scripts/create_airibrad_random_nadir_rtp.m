function create_airibrad_random_nadir_rtp(inpath, outfile_head)
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

% $$$ klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
% $$$ sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';

% Execute user-defined paths
set_process_dirs
addpath(genpath(rtp_sw_dir));
addpath('/home/sergio/MATLABCODE/PLOTTER');  % for hha_lat_subsample_equal_area3
addpath('/asl/matlib/rtptools');   % for cat_rtp
addpath(genpath('/home/sergio/MATLABCODE/matlib/'));  %
                                                      % driver_sarta_cloud_rtp.m
% $$$ addpath(genpath('/home/sbuczko1/git/matlib/'));  % driver_sarta_cloud_rtp.m

% build output filename
% assumes path is like: /asl/data/airs/AIRIBRAD/<year>/<doy>
C = strsplit(inpath, '/');
sYear = C{6};
sDoy = C{7};
outfile_path = fullfile(outfile_head, sYear, 'random', ['era_airibrad_day' ...
                    sDoy '_random.rtp']);

if exist(outfile_path) ~= 0
    fprintf(1, ['>>> Output file exists from previous run. Skipping\' ...
                'n']);
    return;
end

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
    end  % end if i == 1
        
        % find random, nadir subset
        % uses sergio's hha_...3.m
        % need head for input
        [keep, nadir_ind] = hha_lat_subsample_equal_area3(head, prof0);
        
        if i ==1
            prof = rtp_sub_prof(prof0, nadir_ind);
        else
            prof1 = prof;
            prof2 = rtp_sub_prof(prof0, nadir_ind);
            % concatenate new random rtp data into running random rtp structure
            [head, prof] = cat_rtp(head, prof1, head, prof2);
        end
end  % end for i=1:length(files)

% Fix for zobs altitude units
if isfield(prof,'zobs')
   iz = prof.zobs < 20000 & prof.zobs > 20;
   prof.zobs(iz) = prof.zobs(iz) * 1000;
end

% Add in model data
fprintf(1, '>>> Running fill_era... ');
try 
    [prof,head]  = fill_era(prof,head);
catch
    fprintf(2, '>>> ERROR: fill_era failure for %s/%s\n', sYear, ...
            sDoy);
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

% call klayers/sarta cloudy
run_sarta.cloud=+1;
run_sarta.clear=+1;
run_sarta.cumsum=9999;
try
    [prof0, oslabs] = driver_sarta_cloud_rtp(head,hattr,prof,pattr,run_sarta);
catch
    fprintf(2, ['>>> ERROR: failure in driver_sarta_cloud_rtp for ' ...
                '%s/%s\n'], sYear, sDoy);
    return;
end

% profile attribute changes for airibrad
pa = set_attr('profiles', 'robs1', infile);
pa = set_attr(pa, 'rtime', 'TAI:1958');

% Now save the output random rtp file
fprintf(1, '>>> writing output rtp files... ');
try
    rtpwrite(outfile_path, head, hattr, prof0, pa);
catch
    fprintf(2, '>>> ERROR: rtpwrite failure for %s/%s\n', sYear, ...
            sDoy);
    return;
end

fprintf(1, 'Done\n');

            
