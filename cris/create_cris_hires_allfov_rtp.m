function [head, hattr, prof, pattr] = create_cris_hires_allfov_rtp(infile, cfg)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS hires granule file.
    mfilepath = mfilename('fullpath');
    mp = fileparts(mfilepath);
    fprintf(1, '>> Running %s for input: %s\n', mfilepath, infile);

    [sID, sTempPath] = genscratchpath();
    cfg.sID = sID;
    cfg.sTempPath = sTempPath;

    % check for validity of guard channel specifications
    if cfg.nguard > cfg.nsarta
        fprintf(2, ['*** Too many guard channels requested/specified ' ...
                    '(nguard/nsarta = %d/%d)***\n'], cfg.nguard, cfg.nsarta);
        return
    end

    % Load up rtp
    fprintf(1, '> Reading in %s granule file %s\n', cfg.sourcedata, infile);
    switch(cfg.sourcedata)
      case 'ccast'
        [head, hattr, prof, pattr] = ccast2rtp(infile, cfg.nguard, cfg.nsarta);
      case 'nasa'
        [head, hattr, prof, pattr] = uwnc2rtp(infile,cfg);
      case 'noaa'
        [prof, pattr] = readsdr_rtp(infile);
        %-------------------
        % set header values
        %-------------------
        head = struct;
        load(fullfile(mp, 'static', 'CrIS_ancillary'));
        head.nchan = nchan;
        head.ichan = ichan;
        head.vchan = vchan;
        head.pfields = 4; % 4 = IR obs

        %-----------------------
        % set header attributes
        %-----------------------
        hattr = {{'header', 'instid', 'CrIS'}, ...
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

    % ccast granules do not seem to be reporting asc/desc flag properly
    % so fill in by solzen
    prof.iudef(4,:) = (prof.solzen < 90.0);

    % check ichan index order (to avoid problems with rtpwrite)
    temp = size(head.ichan);
    if temp(2) > 1
        head.ichan = head.ichan';
    end
    temp = size(head.vchan);
    if temp(2) > 1
        head.vchan = head.vchan';
    end

    % Need this later
    ichan_ccast = head.ichan;

    % build sub satellite lat point
    [prof, pattr] = build_satlat(prof,pattr);

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
% $$$ head.ngas=2;
    fprintf(1, 'Done\n');

    if ~isempty(cfg.gasscale_opts)
        fprintf(1, '>>> Scaling gas profiles...')
        %%*** add Chris' gas scaling code ***%%
        % add CO2 from GML
        %disp(‘adding GML CO2’)
        if(cfg.gasscale_opts.scaleco2)
            fprintf(1, '\n\t\tCO2...')
            [head,hattr,prof] = fill_co2(head,hattr,prof);
        end
        % add CH4 from GML
        if(cfg.gasscale_opts.scalech4)
            fprintf(1, '\n\t\tCH4...')
            [head,hattr,prof] = fill_ch4(head,hattr,prof);
        end
        % add N2O from GML
        if(cfg.gasscale_opts.scalen2o)
            fprintf(1, '\n\t\tN2O...')
            [head,hattr,prof] = fill_n2o(head,hattr,prof);
        end
        % add CO from MOPITT
        % %if(ismember(5, opts2.glist))
        % %  [head, hattr, prof] = fill_co(head,hattr,prof);
        % %end
        %%*** end Chris' gas scaling code ***%%
        fprintf(1, 'Done\n')
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

    % Run sarta
    fprintf(1, '>>> Running sarta... ');
% $$$ 
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




