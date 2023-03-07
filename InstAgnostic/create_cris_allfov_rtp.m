gfunction [head,hattr,prof,pattr] = create_cris_allfov_rtp(inpath, cfg)

% initialize output to empty structs/cell arrays
    head = struct;
    hattr= {};
    prof = struct;
    pattr = {};

    % validate config settings
    cris_validate_config(cfg)
    
    % read in granule
    fprintf(1, '>>> Read granule: %s...', inpath)
    [h,ha,p,pa] = cris_read_gran(inpath, cfg.reader_opts);
    fprintf(1, 'Done\n')
    
    % Build ancillary data
    fprintf(1, '>>> Building ancillary data (sub sat lat, DEM, emis, etc...')
    [h,ha,p,pa] = rtp_build_ancillary(h,ha,p,pa, cfg.ancillary_opts);
    fprintf(1, 'Done\n')
    
    % Add profile data
    fprintf(1, '>>> Add model: %s...', model)
    [h,ha,p,pa] = rtp_add_model(h,ha,p,pa,cfg.model_opts);
    fprintf(1, 'Done\n');

    % scale gases using chepplew routines, if requested
    if ~isempty(cfg.gasscale_opts)
        [h,ha,p,pa] = rtp_scalegas_preklayers(h,ha,p,pa,cfg.gasscale_opts);
    end
    
    % write out klayers input rtp
    fn_rtp1 = fullfile(cfg.sTempPath, ['cris_' cfg.sID '_klayers_in.rtp']);
    fn_rtp2 = fullfile(cfg.sTempPath, ['cris_' cfg.sID '_klayers_out.rtp']);
    fprintf(1, '>>> Writing klayers input temp file %s ...', fn_rtp1);
    rtpwrite(fn_rtp1,h,ha,p,pa)
    cfg.klayers_opts.klayers_in = fn_rtp1;
    cfg.klayers_opts.klayers_out = fn_rtp2;
    fprintf(1, 'Done\n')

    % run klayers
    fprintf(1, '>>> Running klayers...')
    rtp_run_klayers(cfg.klayers_opts)
    fprintf(1, 'Done\n')

    % Scale gas profiles, if requested
    if ~isempty(cfg.gasscale_opts)
        fprintf(1, '>>> Scaling klayer gas concentrations...')
        cfg.gasscale_opts.rtpfile = fn_rtp2;
        rtp_scalegas_postklayers(cfg.gasscale_opts);
        fprintf(1, 'Done\n')
    end
    
    % run sarta
    fn_rtp3 = fullfile(cfg.sTempPath, ['cris_' cfg.sID '_clrsarta_out.rtp']);
    fn_rtp4 = fullfile(cfg.sTempPath, ['cris_' cfg.sID '_cldsarta_out.rtp']);
    cfg.sarta_opts.sarta_in = fn_rtp2;
    cfg.sarta_opts.clrsarta_out = fn_rtp3;
    cfg.sarta_opts.cldsarta_out = fn_rtp4;
    fprintf(1, '>>> Running sarta...')
    rtp_run_sarta(cfg.sarta_opts);
    fprintf(1, 'Done\n')

    % read in sarta output(s) and grab relevant fields to stuff into profile struct
    [~,~,p_clr,~] = rtpread(cfg.sarta_opts.clrsarta_out);
    [~,~,p_cld,~] = rtpread(cfg.sarta_opts.cldsarta_out);
    
    % check that all is well (how?). If yes, set output rtp structs
    % equal to working structs and exit
    head = h;
    hattr = ha;
    prof = p;
    pattr = pa;
    
    
end

