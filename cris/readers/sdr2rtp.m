function [head,hattr,prof,pattr] = sdr2rtp(infile, cfg)

    [prof, pattr] = readsdr_rtp(infile);
    %-------------------
    % set header values
    %-------------------
    h = struct;
    load(fullfile(cfg.mp, 'static', 'CrIS_ancillary'));
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

end
