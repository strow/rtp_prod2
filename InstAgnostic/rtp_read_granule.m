function [head, hattr, prof, pattr] = rtp_read_granule(granfile, ...
                                                  cfg)
% select instrument and any substyle of granule

switch cfg.inst
  case 'airs'
      switch cfg.instsub
        case 'l1c'
          [head, hattr, prof, pattr] = read_airicrad(granfile);
        case 'l1b'
          [head, hattrm prof, pattr] = read_airibrad(granfile);
      end
  case 'cris'
    switch cfg.instsub
      case 'ccast-hr'
        [head, hattr, prof, pattr] = ccast2rtp(granfile);
      case 'ccast-lr'
        [head, hattr, prof, pattr] = ccast2rtp(granfile);
      case 'ccast-h2l'
        [head, hattr, prof, pattr] = ccast2rtp_hi2lo(granfile);
      case 'nasasdr'
      case 'uwsdr'
    end
  case 'iasi'
    switch cfg.instsub
      case 'l1c'
        [head, hattr, prof, pattr] = iasi2rtp(granfile);
      case 'pcc'
        % TBD
    end
end