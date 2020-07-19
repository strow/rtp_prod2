function [head, hattr, prof, pattr] = create_airicrad_clear_day_rtp(inpath, cfg)
%
% NAME
%   create_airicrad_clear_day_rtp -- wrapper to process AIRICRAD to RTP
%
% SYNOPSIS
%   create_airicrad_clear_day_rtp(infile, outfile_head)
%
% INPUTS
%    infile :   path to input AIRICRAD hdf file
%    outfile_head  : path to output rtp file (minus extension)
%
% L. Strow, Jan. 14, 2015
%
% REQUIRES:
%   rtp_prod2/{util,grib,emis}
%   matlib/{aslutil, rtptools}
%   swutils
%
% DISCUSSION (TBD)
func_name = 'create_airicrad_clear_day_rtp';

% establish local directory structure
currentFilePath = mfilename('fullpath');
[cfpath, cfname, cfext] = fileparts(currentFilePath);
fprintf(1,'> Executing routine: %s\n', currentFilePath);

%*************************************************
% Build configuration ****************************
% $$$ klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
% $$$ sartaclr_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';
klayers_exec = cfg.klayers_exec;
sartaclr_exec = cfg.sartaclr_exec;
%*************************************************

%*************************************************
% Build traceability info ************************
trace.klayers = klayers_exec;
trace.sartaclr = sartaclr_exec;
[status, trace.githash] = githash();
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
fprintf(1, '> Found %d files to process in %s\n', length(files), inpath)
dbtun_ag = [];

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

        
        % profile attribute changes for airicrad
% $$$         pattr = set_attr('profiles', 'robs1', infile);
% $$$         pattr = set_attr(pa, 'rtime', 'TAI:1958');
        FIRSTGRAN = false;
    end  % end if FIRSTGRAN

        % run airs_find_uniform and check for any obs that pass
        % looser land criteria. If such exist, subset to them and
        % continue on to airs_find_clear. If such do not exist,
        % there is no point in running any of the following, so
        % jump to the next granule
        [dbtun, mbt] = airs_find_uniform(head, p);
        iuniform = find(abs(dbtun) < 1.0);
        nuniform = length(iuniform);
        if nuniform > 0
            % subset down to just the uniform pixels
            fprintf(1, '>> Uniformity test: %d accepted\n', ...
                    nuniform);
% $$$             % subset for land obs only
% $$$             LANDTHRESHOLD = 1;
% $$$             iland = find(p.landfrac == LANDTHRESHOLD);
% $$$             KeepObs = intersect(iuniform, iland);

            p = rtp_sub_prof(p, iuniform);
            dbtun_ag = dbtun(iuniform);
            clear dbtun;
            
            fprintf(1, '>>>> Total of %d obs passed uniformity\n', length(p.rtime));

            %    *****************************************
            
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
              case 'era5'
                [p,head,pattr]  = fill_era5(p,head,pattr);
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

            %*************************************************
            % Save the rtp file ******************************
            fprintf(1, '>>> Saving first rtp file... ');
            [sID, sTempPath] = genscratchpath();
            % remove any obs with stemp < 273
            iGoodStemps = find(p.stemp >= 273);
            lGoodStemps = length(iGoodStemps);
            fprintf(1, ['>>> Filtering out low stemp obs: of %d ' ...
                        'initial obs, keeping %d\n'], length(p.stemp), ...
                    lGoodStemps);
            % if all obs flagged for stemp removal, just discard
            % granule and move on
            if lGoodStemps == 0
                fprintf(1, ['>>> All obs miss stemp threshold. ' ...
                            'Discarding granule\n']);
                continue;
            end
            
            if lGoodStemps > 0 & lGoodStemps < length(p.stemp) 
                p = rtp_sub_prof(p, iGoodStemps);
                dbtun_ag = dbtun_ag(iGoodStemps);
            end
            fprintf(1, ['>>> Saved %d obs after filter. Min stemp ' ...
                        'in prof: %.1f\n'], length(p.stemp), min(p.stemp));
            % trim obs count if over the rtp 2.0GB limit (with just
            % clear calcs, somewhere around 60-70k obs)
            MAXOBS = 30000;
            if length(p.rtime) > MAXOBS
                iRand = randperm(length(p.rtime), MAXOBS);
                p = rtp_sub_prof(p, iRand);
                dbtun_ag = dbtun_ag(iRand);
            end

            % set co2ppm
            p.co2ppm = cfg.co2ppm * ones(size(p.stemp));

            % write out first temp file for klayers input
            fn_rtp1 = fullfile(sTempPath, ['airs_' sID '_1.rtp']);
            rtpwrite(fn_rtp1,head,hattr,p,pattr)
            fprintf(1, 'Done\n');
            %*************************************************

            %*************************************************
            % run klayers ************************************
            fprintf(1, '>>> running klayers... ');
            fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);
            klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
                           sTempPath '/kout.txt'];
            unix(klayers_run);
            fprintf(1, 'Done\n');
            %*************************************************

            %*************************************************
            % Run sarta **************************************
            fprintf(1, '>>> Running sarta... ');
            fn_rtp3 = fullfile(sTempPath, ['airs_' sID '_3.rtp']);
            sarta_run = [sartaclr_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
                         ' > ' sTempPath '/sartaout.txt'];
            unix(sarta_run);
            fprintf(1, 'Done\n');
            %*************************************************

            %*************************************************
            % Read in new rcalcs and insert into origin p field
% $$$             stFileInfo = dir(fn_rtp3);
% $$$             fprintf(1, ['*************\n>>> Reading fn_rtp3:\n\tName:\t%s\n\tSize ' ...
% $$$                         '(GB):\t%f\n*************\n'], stFileInfo.name, stFileInfo.bytes/1.0e9);
            [~,~,p2,~] = rtpread(fn_rtp3);
            p.rclr = p2.rcalc;
            p.rcalc = p2.rcalc;
            clear p2;
            head.pfields = 7;

            % temporary files are no longer needed. delete them to make sure we
            % don't fill up the scratch drive.
            delete(fn_rtp1, fn_rtp2, fn_rtp3);
            fprintf(1, 'Done\n');

            %*************************************************

            %*************************************************
            % we have obs that passed uniformity and now have calcs
            % associated so we can do a clear test
            fprintf(1, '>>> running airs_find_clear')
% $$$             fprintf(1, '>>> *** FIND_CLEAR DISABLED ***');
            nobs = length(p.rtime);
            [iflagsc, bto1232, btc1232] = airs_find_clear(head, p, 1:nobs);
            
            iclear_sea    = find(iflagsc == 0 & abs(dbtun_ag) < 0.4 & p.landfrac <= 0.01);
% $$$             iclear_notsea = find(iflagsc == 0 & abs(dbtun_ag) < 1.0 & p.landfrac >  0.01);
% $$$             iclear = union(iclear_sea, iclear_notsea);
% $$$             iclear = find(p.landfrac > 0.95);
            iclear = iclear_sea;
            p.dbtun = dbtun_ag;
            nclear = length(iclear);
            fprintf(1, '>>>> Total of %d uniform obs passed clear test\n', nclear);
            p = rtp_sub_prof(p, iclear);

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
    
    % remove duplicate rcalc (kept to make cat_rtp happy)
    prof = rmfield(prof, 'rcalc');

    fprintf(1, 'Done\n');

    
