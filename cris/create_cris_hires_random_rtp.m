function [head, hattr, prof, pattr] = create_cris_hires_random_rtp(inpath, cfg)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS hires .mat granule file.
    mfilepath = mfilename('fullpath');
    mp = fileparts(mfilepath);
    fprintf(1, '>> Running %s for input: %s\n', mfilepath, inpath);

    [sID, sTempPath] = genscratchpath();
    cfg.sID = sID;
    cfg.sTempPath = sTempPath;

    % check for validity of guard channel specifications
    if cfg.nguard > cfg.nsarta
        fprintf(2, ['*** Too many guard channels requested/specified ' ...
                    '(nguard/nsarta = %d/%d)***\n'], cfg.nguard, cfg.nsarta);
        return
    end

    %*************************************************
    % Build traceability info ************************
    trace.klayers = cfg.klayers_exec;
    trace.sartaclr = cfg.sartaclr_exec;
    [status, trace.githash] = githash();
    trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                                  'd-MMM-y HH:mm:ss Z'));
    fprintf(1, '>>> Run executed %s with git hash %s\n', ...
            trace.RunDate, trace.githash);
    %*************************************************

    %*************************************************
    % Read in day of granules and concatenate to single rtp structure set
    head=struct;hattr={};prof=struct;pattr={};  % initialize output
                                                % vars empty so there
                                                % is something to
                                                % return even in event
                                                % of failure

    % build list of hdf granule files for the day
    switch cfg.sourcedata
      case 'ccast'
        files = dir(fullfile(inpath, '*.mat'));
      case 'nasa'
        files = dir(fullfile(inpath, '*.nc'));
      case 'noaa'
        files = dir(fullfile(inpath, '*.h5'));
    end

    if isempty(files)
        fprintf(2, ['>> ERROR :: No granule files found in %s.\n>> ' ...
                    'EXITING\n'], inpath);
        return;
    end
    fprintf(1, '>>> Found %d granule files to be read\n', ...
            length(files));

    stride=1;
    FIRSTGRAN=true;
    for i=1:stride:length(files)
        % Read ccast granule file
        infile = fullfile(inpath, files(i).name);
        fprintf(1, '>>> Reading input file: %s  ', infile);
        
        try
            switch(cfg.sourcedata)
              case 'ccast'
                [h_gran, ha_gran, p_gran, pa_gran] = ccast2rtp(infile, cfg.nguard, cfg.nsarta);
              case 'nasa'
                [h_gran, ha_gran, p_gran, pa_gran] = uwnc2rtp(infile,cfg);
              case 'noaa'
                [p_gran, pa_gran] = readsdr_rtp(infile);
                %-------------------
                % set header values
                %-------------------
                h_gran = struct;
                load(fullfile(mp, 'static', 'CrIS_ancillary'));
                h_gran.nchan = nchan;
                h_gran.ichan = ichan;
                h_gran.vchan = vchan;
                h_gran.pfields = 4; % 4 = IR obs

                %-----------------------
                % set header attributes
                %-----------------------
                ha_gran = {{'header', 'instid', 'CrIS'}, ...
                           {'header', 'reader', 'readsdr_rtp'}, ...
                          };

              case 'climcaps'
                [h_gran, ha_gran, p_gran, pa_gran] = climcaps2rtp(infile, cfg);
              case 'ccast_hi2lo'
                [h_gran, ha_gran, p_gran, pa_gran] = ccast2rtp_hi2lo(infile, cfg.nguard);
              case 'ccast_lowres'
                [h_gran, ha_gran, p_gran, pa_gran] = ccast2rtp(infile, cfg.nguard, cfg.nsarta);

              otherwise
                error('Invalid data source %s for granule read', cfg.sourcedata)
                
            end

        catch
            fprintf(2, ['>>> ERROR: failure reading granule %s. ' ...
                        'Skipping.\n'], infile);
            continue
        end
        fprintf(1, 'Done.\n');
        % check ichan index order (to avoid problems with rtpwrite)
        temp = size(h_gran.ichan);
        if temp(2) > 1
            h_gran.ichan = h_gran.ichan';
        end
        temp = size(h_gran.vchan);
        if temp(2) > 1
            h_gran.vchan = h_gran.vchan';
        end

        % filter out desired FOVs/scan angles
        fprintf(1, '>>> Running get_equal_area_sub_indices for random selection... \n');
        fors = [1:30];

        nadir = ismember(p_gran.xtrack,fors);

        % rtp has a 2GB limit so we have to scale number of kept FOVs
        % to stay within that as an absolute limit. Further, we
        % currently restrict obs count in random to ~20k to match
        % historical AIRXBCAL processing
        limit = 20000;  % number of obs to keep
        nswath = 45;  % length of ccast granules
        ngrans = 240;  % number of granules per day
        nfovs = 9;  % number of FOVs per FOR
        maxobs = nswath * length(fors) * nfovs * ngrans;
        scale = (limit/maxobs)*1.6; % preserves ~65k obs/day 
        randoms = get_equal_area_sub_indices(p_gran.rlat, scale);
        nrinds = find(nadir & randoms);
        if length(nrinds) == 0
            return
        end
        p_gran = rtp_sub_prof(p_gran, nrinds);
        fprintf(1, '>>> Found %d obs after random selection\n', length(p_gran.rtime));

        % build sub satellite lat point
        [p_gran, pa_gran] = build_satlat(p_gran,pa_gran);
        % sarta puts limits on satzen/satang (satzen comes out in
        % the
        % profiles form ccast2rtp) so, filter to remove profiles
        % outside this range to keep sarta from failing.
        inrange = find(p_gran.satzen >= 0.0 & p_gran.satzen < ...
                       63.0);
        p_gran = rtp_sub_prof(p_gran, inrange);
        clear inrange;

        % Need this later
        ichan_ccast = h_gran.ichan;

        % now that we've trimmed off many (most?) of the obs,
        % concatenate into a single daily rtp structure
        if FIRSTGRAN
            head = h_gran;
            hattr = ha_gran;
            prof = p_gran;
            pattr = pa_gran;
            
            FIRSTGRAN=false;
        else
            [head, prof] = cat_rtp(head, prof, h_gran, p_gran);
        end

    end % end loop over granules
    
    % Add profile data
    fprintf(1, '>>> Add model: %s...', cfg.model)
    switch cfg.model
      case 'ecmwf'
        [prof,head,pattr]  = fill_ecmwf(prof,head,pattr,cfg);
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
    fprintf(1, 'Done\n');
    if ~isempty(cfg.gasscale_opts)
        %%*** add Chris' gas scaling code ***%%
        % add CO2 from GML
        %disp(‘adding GML CO2’)
        if(cfg.gasscale_opts.scaleco2)
            [head,hattr,prof] = fill_co2(head,hattr,prof);
        end
        % add CH4 from GML
        if(cfg.gasscale_opts.scalech4)
            [head,hattr,prof] = fill_ch4(head,hattr,prof);
        end
        % add N2O from GML
        if(cfg.gasscale_opts.scalen2o)
            [head,hattr,prof] = fill_n2o(head,hattr,prof);
        end
        % add CO from MOPITT
        % %if(ismember(5, opts2.glist))
        % %  [head, hattr, prof] = fill_co(head,hattr,prof);
        % %end
        %%*** end Chris' gas scaling code ***%%
    end

    % Add landfrac, etc.
    fprintf(1, '>>> Running rtpadd_usgs_10dem...');
    [head, hattr, prof, pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);
    fprintf(1, 'Done\n');

    % Add Dan Zhou's emissivity and Masuda emis over ocean
    % Dan Zhou's one-year climatology for land surface emissivity and
    % standard routine for sea surface emissivity
    fprintf(1, '>>> Running rtp_add_emis_single...');
    [prof,pattr] = rtp_add_emis_single(prof,pattr);
    fprintf(1, 'Done\n');
    % run klayers
    fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
    fprintf(1, '>>> Writing klayers input temp file %s ...', fn_rtp1);
    rtpwrite(fn_rtp1,head,hattr,prof,pattr)
    fprintf(1, 'Done\n')
    fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
    unix([cfg.klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath ...
          '/klayers_' sID '_stdout'])
    fprintf(1, 'Done\n');

    % scale gas concentrations, if requested in config
    if ~isempty(cfg.gasscale_opts)
        fprintf(1, '>>> Post-klayers linear gas scaling...')
        % read in klayers output
        [hh,hha,pp,ppa] = rtpread(fn_rtp2);
        delete(fn_rtp2)
        if isfield(cfg.gasscale_opts, 'scaleco2')
            fprintf(1, '\n\t\tCO2...')
            pp.gas_2 = pp.gas_2 * cfg.gasscale_opts.scaleco2;
            ppa{end+1} = {'profiles' 'scaleCO2' sprintf('%f', cfg.gasscale_opts.scaleco2)};
        end
        if isfield(cfg.gasscale_opts, 'scalech4')
            fprintf(1, '\n\t\tCH4...')
            pp.gas_6 = pp.gas_6 * cfg.gasscale_opts.scalech4;
            ppa{end+1} = {'profiles' 'scaleCH4' sprintf('%f', cfg.gasscale_opts.scalech4)};        
        end
        %%*** Chris' fill_co is not ready so use basic scaling for now
        if isfield(cfg.gasscale_opts,'scaleco')
            fprintf(1, '\n\t\tCO...')
            pp.gas_5 * cfg.gasscale_opts.scaleco;
            ppa{end+1} = {'profiles' 'scaleCO' sprintf('%f', cfg.gasscale_opts.scaleco)};
        end
        %%***
        rtpwrite(fn_rtp2,hh,hha,pp,ppa)
        fprintf(1, 'Done\n')
    end

% $$$ % run driver_sarta_cloud to handle klayers and sarta runs
    sarta_cfg.clear=cfg.clear;
    sarta_cfg.cloud=cfg.cloud;
    sarta_cfg.cumsum=cfg.cumsum;
    sarta_cfg.klayers_code = cfg.klayers_exec;
    sarta_cfg.sartaclear_code = cfg.sartaclr_exec;
    sarta_cfg.sartacloud_code = cfg.sartacld_exec;

    prof0 = driver_sarta_cloud_rtp(head, hattr, prof, pattr, ...
                                   sarta_cfg);
    % pull calcs out of prof0 and stuff into pre-klayers prof
    [~,~,prof,~] = rtpread(fn_rtp1);
    prof.rclr = prof0.rclr;
    prof.rcld = prof0.rcld;

    % also capture cloud fields
    prof.cfrac = prof0.cfrac;   
    prof.cfrac12 = prof0.cfrac12; 
    prof.cfrac2 = prof0.cfrac2;  
    prof.cngwat = prof0.cngwat;  
    prof.cngwat2 = prof0.cngwat2; 
    prof.cprbot = prof0.cprbot;  
    prof.cprbot2 = prof0.cprbot2; 
    prof.cprtop = prof0.cprtop;  
    prof.cprtop2 = prof0.cprtop2; 
    prof.cpsize = prof0.cpsize;  
    prof.cpsize2 = prof0.cpsize2; 
    prof.ctype = prof0.ctype;   
    prof.ctype2 = prof0.ctype2;  
    prof.co2ppm = prof0.co2ppm;

    %*************************************************
    % Make head reflect calcs
    head.pfields = 7;  % robs, model, calcs


end  % end function




