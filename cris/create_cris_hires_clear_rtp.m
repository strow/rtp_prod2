function [head, hattr, prof, pattr] = create_cris_hires_clear_rtp(inpath, cfg)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS .mat granule file.
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

        %*********
        % cris_find_uniform is predicated on having a full 9x30x45
        % granule. We may have to turn the following NaN check into
        % a 'throw out this granule and continue to next' until
        % things can be made more flexible
        %*********
        % check rtime values for NaN. subset out obs with such
        % rtimes (in all such cases found so far, Nans are in a
        % contiguous block and all profile fields are NaN'd)
        gnans = isnan(p_gran.rtime);
        nnans = sum(gnans);
        nobs = length(p_gran.rtime);
        if nnans | nobs ~= 12150
            fprintf(2,'>> Granule %d contains NaNs or is wrong size. SKIPPING\n',i);
% $$$             nan_inds = find(~gnans);
% $$$             p_gran = rtp_sub_prof(p_gran,nan_inds);
            continue;
        end

        % check pixel uniformity. If no FOR/FOVs satisfy
        % uniformity, no point in continuing to process this
        % granule
        uniform_cfg = struct;
        uniform_cfg.uniform_test_channel = 961;
        uniform_cfg.uniform_bt_threshold = 0.4; 
        [iuniform, amax_keep] = cris_find_uniform(h_gran, p_gran, uniform_cfg);
        
        % subset out non-uniform FOVs
        nuniform = length(iuniform);
        if 0 == nuniform
            fprintf(2,['>> No uniform FOVs found for granule %d. ' ...
                       'SKIPPING\n'],i)
            continue;
        end
        
        fprintf(1, '>> Uniform obs found: %d/12150\n', nuniform);
        p_gran = rtp_sub_prof(p_gran,iuniform);

        % check that [iv]chan are column vectors
        temp = size(h_gran.ichan);
        if temp(2) > 1
            h_gran.ichan = h_gran.ichan';
        end
        temp = size(h_gran.vchan);
        if temp(2) > 1
            h_gran.vchan = h_gran.vchan';
        end

        
        % Need this later
        ichan_ccast = h_gran.ichan;

        % build sub-satellite lat point
        [p_gran, pa_gran] = build_satlat(p_gran, pa_gran);
        % sarta puts limits on satzen/satang (satzen comes out in
        % the
        % profiles form ccast2rtp) so, filter to remove profiles
        % outside this range to keep sarta from failing.
        inrange = find(p_gran.satzen >= 0.0 & p_gran.satzen < ...
                       63.0);
        p_gran = rtp_sub_prof(p_gran, inrange);
        clear inrange;

        % Add p_gran profile data
        switch cfg.model
          case 'ecmwf'
            [p_gran,h_gran,pa_gran]=fill_ecmwf(p_gran,h_gran,pa_gran,cfg);
          case 'era'
            [p_gran,h_gran,pa_gran]=fill_era(p_gran,h_gran,pa_gran);
          case 'merra'
            [p_gran,h_gran,pa_gran]=fill_merra(p_gran,h_gran,pa_gran);    
        end
        
        % on to next granule if p_gran is empty after model
        % (missing model files, typically)
        if isempty(fieldnames(p_gran))
            continue
        end
        
        % rtp now has p_gran and obs data ==> 5
        h_gran.pfields = 5;
        [nchan,nobs] = size(p_gran.robs1);
        h_gran.nchan = nchan;
        h_gran.ngas=2;

        if ~isempty(cfg.gasscale_opts)
            %%*** add Chris' gas scaling code ***%%
            % add CO2 from GML
            %disp(‘adding GML CO2’)
            if(cfg.gasscale_opts.scaleco2)
                [h_gran,ha_gran,p_gran] = fill_co2(h_gran,ha_gran,p_gran);
            end
            % add CH4 from GML
            if(cfg.gasscale_opts.scalech4)
                [h_gran,ha_gran,p_gran] = fill_ch4(h_gran,ha_gran,p_gran);
            end
            % add N2O from GML
            if(cfg.gasscale_opts.scalen2o)
                [h_gran,ha_gran,p_gran] = fill_n2o(h_gran,ha_gran,p_gran);
            end
            % add CO from MOPITT
            % %if(ismember(5, opts2.glist))
            % %  [head, hattr, prof] = fill_co(head,hattr,prof);
            % %end
            %%*** end Chris' gas scaling code ***%%
        end
        
        % Add landfrac, etc.
        [h_gran, ha_gran, p_gran, pa_gran] = rtpadd_usgs_10dem(h_gran,ha_gran,p_gran,pa_gran);

        % Add Dan Zhou's emissivity and Masuda emis over ocean
        % Dan Zhou's one-year climatology for land surface emissivity and
        % standard routine for sea surface emissivity
        fprintf(1, '>>> Running rtp_ad_emis...');
        [p_gran,pa_gran] = rtp_add_emis_single(p_gran,pa_gran);
        fprintf(1, 'Done\n');
        

        % run klayers
        MAXOBS = 60000;
        if length(p_gran.rtime) > MAXOBS
            p_gran = rtp_sub_p_gran(p_gran, randperm(length(p_gran.rtime), MAXOBS));
        end

        fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
        rtpwrite(fn_rtp1,h_gran,ha_gran,p_gran,pa_gran);
        fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
        unix([cfg.klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath '/klayers_stdout'])

        % scale gas concentrations, if requested in config
        %        if isfield(cfg, 'scaleco2') | isfield(cfg, 'scalech4') | isfield(cfg, 'scaleco')
        if ~isempty(cfg.gasscale_opts)
            % read in klayers output
            [hh,hha,pp,ppa] = rtpread(fn_rtp2);
            delete(fn_rtp2)
            if isfield(cfg.gasscale_opts, 'scaleco2')
                pp.gas_2 = pp.gas_2 * cfg.gasscale_opts.scaleco2;
                ppa{end+1} = {'profiles' 'scaleCO2' sprintf('%f', cfg.gasscale_opts.scaleco2)};
            end
            if isfield(cfg.gasscale_opts, 'scalech4')
                pp.gas_6 = pp.gas_6 * cfg.gasscale_opts.scalech4;
                ppa{end+1} = {'profiles' 'scaleCH4' sprintf('%f', cfg.gasscale_opts.scalech4)};        
            end
            %%*** Chris' fill_co is not ready so use basic scaling for now
            if isfield(cfg.gasscale_opts,'scaleco') 
                pp.gas_5 * cfg.gasscale_opts.scaleco;
                ppa{end+1} = {'profiles' 'scaleCO' sprintf('%f', cfg.gasscale_opts.scaleco)};
            end
            %%*** 
            rtpwrite(fn_rtp2,hh,hha,pp,ppa)
        end
        
        % run sarta

        if strcmp('csarta', cfg.rta)
            fprintf(1, '>>> Running CrIS sarta... ');
            fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
            sarta_run = [cfg.sartaclr_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
                         ' > ' sTempPath '/sartaout.txt'];
            unix(sarta_run);

            % read in sarta results to capture rcalc
            [~,~,p,~] = rtpread(fn_rtp3);
            p_gran.rclr = p.rcalc;
            clear p;
            fprintf(1, 'Done\n');
        else if strcmp('isarta', cfg.rta)
                fprintf(1, '>>> Running IASI sarta... ');
                cfg.fn_rtp2 = fn_rtp2;
                [hh,hha,pp,ppa] = rtpread(fn_rtp2);
                [~, ~, p, ~] = run_sarta_iasi(hh,hha,pp,ppa,cfg);
                p_gran.rclr = p.rclr;
                fprintf(1, 'Done\n');
        end
        end  % end run sarta 
        
        % now that we have calcs, find clear FOVs
% $$$         iobs2check = 1:length(p_gran.rtime);
        wntest = cfg.uniform_test_channel;
        wnindex = find(h_gran.vchan > wntest,1);
        fprintf(1, '>> Clear determination using index=%d, wn=%.1f\n', ...
                wnindex, h_gran.vchan(wnindex));
        bto = rad2bt(h_gran.vchan(wnindex),p_gran.robs1(wnindex,: ...
                                                       ));
        btc = rad2bt(h_gran.vchan(wnindex),p_gran.rclr(wnindex,:));
        iclear = find(bto-btc > -4 & p_gran.landfrac <= 0.01);
        nclear = length(iclear);
        fprintf(1, '>>>> Total of %d uniform obs passed clear test\n', nclear);
        p_gran = rtp_sub_prof(p_gran, iclear);

        if FIRSTGRAN
            prof = p_gran;
            head = h_gran;
            hattr = ha_gran;
            pattr = pa_gran;
            FIRSTGRAN = false;
        else
            % concatenate new random rtp data into running random rtp structure
            [head, prof] = cat_rtp(head, prof, h_gran, p_gran);
        end

        adflag = unique(p_gran.iudef(4,:));
        fprintf(1, '>>> Asc/Desc flag values: %d\n', adflag);
        
    end  % end for i=1:length(files)
    clear p_gran;

end

