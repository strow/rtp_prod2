function [head, hattr, prof, pattr] = create_airicrad_dcc_day_rtp(inpath, cfg)
%
% NAME
%   create_airicrad_dcc_day_rtp -- wrapper to process AIRICRAD to RTP
%
% SYNOPSIS
%   create_airicrad_dcc_day_rtp(inpath, cfg)
%
% INPUTS
%    infile :   path to directory of input AIRICRAD hdf files
%    cfg    :   path to configuration file
%
% L. Strow, Jan. 14, 2015
%
% REQUIRES:
%   rtp_prod2/{util,grib,emis}
%   matlib/{aslutil, rtptools}
%   swutils
%
% DISCUSSION (TBD)
func_name = 'create_airicrad_dcc_day_rtp';

% establish local directory structure
currentFilePath = mfilename('fullpath');
[cfpath, cfname, cfext] = fileparts(currentFilePath);
fprintf(1,'> Executing routine: %s\n', currentFilePath);

%*************************************************
% Build configuration ****************************
klayers_exec = 'NOT RUN';
sartaclr_exec   = 'NOT RUN';
%*************************************************

%*************************************************
% Build traceability info ************************
trace.klayers = klayers_exec;
trace.sartaclr = sartaclr_exec;
[status, trace.githash] = githash;
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                              'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);
%*************************************************

load(fullfile(cfpath, 'static/sarta_chans_for_l1c.mat'));

% This version operates on a day of AIRICRAD granules and
% concatenates the subset of clear obs into a single output file
% >> inpath is the path to an AIRS day of data
% /asl/data/airs/AIRICRAD/<year>/<doy>
files = dir(fullfile(inpath, '*.hdf'));

FIRSTGRAN = true;
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
    if length(p.rtime) ~= 12150
        fprintf(1, ['>>> GRANULE MISSING OBS: Discarding granule %s\' ...
                    'n'], infile);
        continue
    end
    fprintf(1, 'Done. \n')
    
    if FIRSTGRAN % only need to build the head structure once but, we do
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
                {'header' 'sartaclr_exec' sartaclr_exec} };
        
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
        fprintf(1, '>> Header struct built\n');

        
% $$$         % profile attribute changes for airicrad
% $$$         pattr = set_attr('profiles', 'robs1', infile);
% $$$         pattr = set_attr(pa, 'rtime', 'TAI:1958');
        FIRSTGRAN = false;
    end  % end if FIRSTGRAN

        % Check for observations with deep convective cloud
        % signatures (DCC)
        idcc = airs_find_dcc(head, p);
        ndcc = length(idcc);
        if ndcc > 0
            % subset down to just the uniform pixels
            fprintf(1, '>> DCC test: %d found\n', ndcc);
            p = rtp_sub_prof(p, idcc);
            
            %*************************************************
            % rtp data massaging *****************************
            % Fix for zobs altitude units
            if isfield(p,'zobs')
                p = fix_zobs(p);
            end
            %*************************************************

            %*************************************************
            % Add in model data ******************************
            fprintf(1, '>>> Add model: %s...', cfg.model)
            switch cfg.model
              case 'ecmwf'
                [p,head,pattr]  = fill_ecmwf(p,head,pattr);
              case 'era'
                [p,head,pattr]  = fill_era(p,head,pattr);
              case 'merra'
                [p,head,pattr]  = fill_merra(p,head,pattr);
            end
            % check that we have same number of model entries as we do obs because
            % corrupt model files will leave us with an unbalanced rtp
            % structure which WILL fail downstream (ideally, this should be
            % checked for in the fill_* routines but, this is faster for now)
            [~,nobs] = size(p.robs1);
            [~,mobs] = size(p.gas_1);
            if mobs ~= nobs
                fprintf(2, ['*** ERROR: number of model entries does not agree ' ...
                            'with nobs ***\n'])
                return;
            end
            clear nobs mobs
            head.pfields = 5;  % robs, model
            fprintf(1, 'Done\n');
            %*************************************************

            %*************************************************
            % Add surface emissivity *************************
            % Dan Zhou's one-year climatology for land surface emissivity and
            % standard routine for sea surface emissivity
            fprintf(1, '>>> Running rtp_add_emis...');
            [p,pattr] = rtp_add_emis(p,pattr);
            fprintf(1, 'Done\n');
            %*************************************************

            % klayers/sarta results don't actually make much sense
            % for DCC obs so, where those would normally get run
            % here, we will skip this processing
            %*************************************************

            % concatenate rtp structs
            if ~exist('prof')
                prof = p;
            else
                [head, prof] = cat_rtp(head, prof, head, p);
            end
        else
            continue
        end
        
end  % end for i=1:length(files)

    fprintf(1, 'Done\n');

    
