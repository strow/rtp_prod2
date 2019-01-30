function [head, hattr, prof, pattr] = create_cris_ccast_hires_clear_day_rtp(inpath, cfg)
% PROCESS_CRIS_HIRES process one granule of CrIS data
%
% Process a single CrIS .mat granule file.
    func_name = 'create_cris_ccast_hires_clear_day_rtp';
    
% Execute user-defined paths *********************
    REPOBASEPATH = '/home/sbuczko1/git/';
% $$$ REPOBASEPATH = '/asl/packages/';

    PKG = 'rtp_prod2';
    % era/ecmwf/merra, emissivity, etc
    addpath(sprintf('%s/%s/util', REPOBASEPATH, PKG));
    addpath(sprintf('%s/%s/grib', REPOBASEPATH, PKG));
    addpath(sprintf('%s/%s/emis', REPOBASEPATH, PKG));
    addpath(genpath(sprintf('%s/%s/cris', REPOBASEPATH, PKG)));

    PKG = 'swutils'
    % genscratchpath
    addpath(sprintf('%s/%s', REPOBASEPATH, PKG));

    PKG = 'ccast'
    % ccast2rtp, cris_[iv]chan
    addpath(sprintf('%s/%s/motmsc/rtp_sarta', REPOBASEPATH, PKG));
    % fixmyQC
    addpath(sprintf('%s/%s/source', REPOBASEPATH, PKG));

    PKG = 'matlib';
    % cat_rtp
    addpath('/asl/matlib/rtptools'); 
    addpath('/asl/matlib/time');
    
% $$$ % Need these two paths to use iasi2cris.m in iasi_decon
% $$$ addpath /asl/packages/iasi_decon   % seq_match?
% $$$ addpath /asl/packages/ccast/source  % fixmyQC?

    % ************************************************

    fprintf(1, '>> Running create_cris_ccast_hires_rtp for input: %s\n', ...
            inpath);

    % ************************************************
    % read in configuration options from 'cfg' *******
    klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
    if isfield(cfg, 'klayers_exec')
        klayers_exec = cfg.klayers_exec;
    end

    sartaclr_exec  = ['/asl/packages/sartaV108/BinV201/' ...
                   'sarta_iasi_may09_wcon_nte'];
    if isfield(cfg, 'sartaclr_exec')
        sartaclr_exec = cfg.sarta_exec;
    end
    nguard = 2;  % number of guard channels
    if isfield(cfg, 'nguard')
        nguard = cfg.nguard;
    else
        cfg.nguard = nguard;
    end
    nsarta = 4;  % number of sarta guard channels
    if isfield(cfg, 'nsarta')
        nsarta = cfg.nsarta;
    else
        cfg.nsarta = nsarta;
    end
    % check for validity of guard channel specifications
    if nguard > nsarta
        fprintf(2, ['*** Too many guard channels requested/specified ' ...
                    '(nguard/nsarta = %d/%d)***\n'], nguard, nsarta);
        return
    end
    % ************************************************

    % Pick up system/slurm info **********************
    [sID, sTempPath] = genscratchpath();

    cfg.sID = sID;
    cfg.sTempPath = sTempPath;
    % ************************************************

    %*************************************************
    % Build traceability info ************************
    trace.klayers = klayers_exec;
    trace.sartaclr = sartaclr_exec;
    trace.githash = githash(func_name);
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
    files = dir(fullfile(inpath, '*.mat'));
    if isempty(files)
        fprintf(2, ['>> ERROR :: No granule files found in %s.\n>> ' ...
                    'EXITING\n'], inpath);
        return;
    end
    fprintf(1, '>>> Found %d granule files to be read\n', ...
            length(files));

    for i=1:length(files)
        % Read ccast granule file
        infile = fullfile(inpath, files(i).name);
        fprintf(1, '>>> Reading input file: %s  ', infile);
        
        try
            [h_gran, ha_gran, p_gran, pa_gran] = ccast2rtp(infile, nguard, nsarta);
            %%** second parameter sets up the use of 4 CrIS guard
            %%channels. Looking at h_gran.ichan and h_gran.vchan shows some
            %%similarity to the cris channel description in
            %%https://hyperearth.wordpress.com/2013/07/09/cris-rtp-formats/, at
            %%least for the first set of guard channels
        catch
            fprintf(2, ['>>> ERROR: failure in ccast2rtp for granule %s. ' ...
                        'Skipping.\n'], infile);
            continue
        end
        fprintf(1, 'Done.\n');

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

        % Add p_granile data
        switch cfg.model
          case 'ecmwf'
            [p_gran,h_gran,pa_gran]=fill_ecmwf(p_gran,h_gran,pa_gran,cfg);
          case 'era'
            [p_gran,h_gran,pa_gran]=fill_era(p_gran,h_gran,pa_gran);
          case 'merra'
            [p_gran,h_gran,pa_gran]=fill_merra(p_gran,h_gran,pa_gran);    
        end

        % rtp now has p_granile and obs data ==> 5
        h_gran.pfields = 5;
        [nchan,nobs] = size(p_gran.robs1);
        h_gran.nchan = nchan;
        h_gran.ngas=2;


        % Add landfrac, etc.
        [h_gran, ha_gran, p_gran, pa_gran] = rtpadd_usgs_10dem(h_gran,ha_gran,p_gran,pa_gran);

        % Add Dan Zhou's emissivity and Masuda emis over ocean
        % Dan Zhou's one-year climatology for land surface emissivity and
        % standard routine for sea surface emissivity
        fprintf(1, '>>> Running rtp_ad_emis...');
        [p_gran,pa_gran] = rtp_add_emis_single(p_gran,pa_gran);
        fprintf(1, 'Done\n');

        % run Sergio's subsetting routine
        fprintf(1, '>> Building basic filtering flags (uniform_clear_template...)\n');
% $$$ % $$$ px = rmfield(p_gran,'rcalc');
% $$$ hx = h_gran; hx.pfields = 5;
        fprintf(1, '>>> NGAS = %d\n', h_gran.ngas);

        try
            px = uniform_clear_template_lowANDhires_HP(h_gran,ha_gran,p_gran,pa_gran); %% super (if it works)
        catch
            fprintf(2, ['>>> FAILURE in uniform_clear_template_lowANDhires_HP ' ...
                        'for granule %s   SKIPPING\n'], infile)
            continue
        end
        
        % subset out the clear
        % output rtp splitting from airxbcal processing
        % Subset into four types and save separately
        iclear = find(px.iudef(1,:) == 1);
        p_gran = rtp_sub_prof(px,iclear);
        clear px;


        if i == 1
            prof = p_gran;
            head = h_gran;
            hattr = ha_gran;
            pattr = pa_gran;
        else
            % concatenate new random rtp data into running random rtp structure
            [head, prof] = cat_rtp(head, prof, head, p_gran);
        end

        adflag = unique(prof.iudef(4,:));
        fprintf(1, '>>> Asc/Desc flag values: %d\n', adflag);
        
    end  % end for i=1:length(files)
        clear p_gran;
        

        % run klayers
        MAXOBS = 60000;
        if length(prof.rtime) > MAXOBS
            prof = rtp_sub_prof(prof, randperm(length(prof.rtime), MAXOBS));
        end

        fn_rtp1 = fullfile(sTempPath, ['cris_' sID '_1.rtp']);
        rtpwrite(fn_rtp1,head,hattr,prof,pattr);
        fn_rtp2 = fullfile(sTempPath, ['cris_' sID '_2.rtp']);
        unix([klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' sTempPath '/klayers_stdout'])

        % scale gas concentrations, if requested in config
        if isfield(cfg, 'scaleco2') | isfield(cfg, 'scalech4')
            % read in klayers output
            [hh,hha,pp,ppa] = rtpread(fn_rtp2);
            delete fn_rtp2
            if isfield(cfg, 'scaleco2')
                pp.gas_2 = pp.gas_2 * cfg.scaleco2;
                pattr{end+1} = {'profiles' 'scaleCO2' sprintf('%f', cfg.scaleco2)};
            end
            if isfield(cfg, 'scalech4')
                pp.gas_6 = pp.gas_6 * cfg.scalech4;
                pattr{end+1} = {'profiles' 'scaleCH4' sprintf('%f', cfg.scalech4)};        
            end
            rtpwrite(fn_rtp2,hh,hha,pp,ppa)
        end
        
        % run sarta

        if strcmp('csarta', cfg.rta)
            fprintf(1, '>>> Running CrIS sarta... ');
            fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
            sarta_run = [sartaclr_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
                         ' > ' sTempPath '/sartaout.txt'];
            unix(sarta_run);

            % read in sarta results to capture rcalc
            [~,~,p,~] = rtpread(fn_rtp3);
            prof.rclr = p.rcalc;
            clear p;
            fprintf(1, 'Done\n');
        else if strcmp('isarta', cfg.rta)
                fprintf(1, '>>> Running IASI sarta... ');
                cfg.fn_rtp2 = fn_rtp2;
                [hh,hha,pp,ppa] = rtpread(fn_rtp2);
                [~, ~, p, ~] = run_sarta_iasi(hh,hha,pp,ppa,cfg);
                prof.rclr = p.rclr;
                fprintf(1, 'Done\n');
        end
    end  % end run sarta 
        
