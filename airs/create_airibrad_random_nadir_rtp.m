function [head, hattr, prof, pattr] = create_airibrad_random_nadir_rtp(inpath, cfg)
%
% NAME
%   create_airibrad_rtp -- wrapper to process AIRIBRAD to RTP
%
% SYNOPSIS
%   create_airibrad_rtp(inpath, cfg)
%
% INPUTS
%    inpath :   path to input AIRIBRAD hdf file
%    cfg    :   configuration struct (OPTIONAL)
%
% REQUIRES
%    swutils  :  githash
%
% DISCUSSION (TBD)
% This version operates on a day of AIRIBRAD granules
% and concatenates the subset of random obs into a single output file
% >> inpath is the path to an AIRS day of data
% /asl/data/airs/AIRIBRAD/<year>/<doy>
func_name = 'create_airibrad_random_nadir_rtp';

% establish configuration defaults
klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = ['/asl/packages/sartaV108/BinV201/' ...
                'sarta_apr08_m140_wcon_nte'];
sartacld_exec = '';
model = 'era'; 
% read in configuration (if present) and modify defaults
if nargin == 2   % config structure present
    if isfield(cfg, 'klayers_exec')
        klayers_exec = cfg.klayers_exec;
    end
    if isfield(cfg, 'sarta_exec')
        sarta_exec = cfg.sarta_exec;
    end
    if isfield(cfg, 'sartacld_exec')
        sartacld_exec = cfg.sartacld_exec;
    end
    if isfield(cfg, 'model')
        model = cfg.model;
    end
end

% Execute user-defined paths
addpath('/home/sbuczko1/git/swutils');
addpath('../readers');
addpath('/asl/matlib/rtptools');   % for cat_rtp
addpath(genpath('/home/sbuczko1/git/matlib/'));  % driver_sarta_cloud_rtp.m


trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                              'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

head=struct;hattr={};prof=struct;pattr={};  % initialize output
                                            % vars empty so there
                                            % is something to
                                            % return even in event
                                            % of failure

% build list of hdf granule files for the day
files = dir(fullfile(inpath, '*.hdf'));
if isempty(files)
    % kick off error report and exit back to calling function
end
fprintf(1, '>>> Found %d granule files to be read\n', ...
        length(files));
% cfg.instparams = [135, 90, 1, length(files)];

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
                {'header' 'rundate' trace.RunDate}, ...
                {'header' 'klayers_exec' klayers_exec}, ...
                {'header' 'sarta_exec' sarta_exec} };

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

        p = equal_area_nadir_select(prof0,cfg);  % select for
                                                 % random/nadir obs
        if ~exist('prof')
            prof = p;
        else
            % concatenate new random rtp data into running random rtp structure
            [head, prof] = cat_rtp(head, prof, head, p);
        end
end  % end for i=1:length(files)
    clear p0 p;

    % Fix for zobs altitude units
    if isfield(prof,'zobs')
        iz = prof.zobs < 20000 & prof.zobs > 20;
        prof.zobs(iz) = prof.zobs(iz) * 1000;
    end

    if (~strcmp(cfg.model, 'nomodel'))
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
    end  % end if (~strcmp(cfg.model, 'nomodel'))

        % profile attribute changes for airibrad
        pattr = set_attr('profiles', 'robs1', infile);
        pattr = set_attr(pattr, 'rtime', 'TAI:1958');

        fprintf(1, 'Done\n');

        
