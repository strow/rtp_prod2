function [outpath, outfilename] = rtp_build_output(granfile, cfg)

switch cfg.inst
  case 'airs'
    % L1C (airicrad) filenames look like:
    % AIRS.YYYY.MM.DD.GGG.L1C.AIRS_RAD.v6.7.2.0.G11111111111.hdf
    [fpath, fname, fext] = fileparts(granfile);
    C = strsplit(fname, '.');
    D = sscanf(sprintf(' %s', C{2:4}), '%f', [1,3]);
    dt = datetime(D);
    dt.Format='DDD';   % convert to day of year
    
    % output path looks like /asl/<inst>/<????>/<rtptype>/<year>/<doy>
    %     e.g. /asl/airs/l1c_v672/allfov/2009/132
    outpath = sprintf('/asl/airs/l1c_v672/%s/%s/%s',cfg.rtptype, ...
                      C{2},char(dt));

    % output filename looks like
    % <rtptype>_<model>_<dtype>_d<date>{_<gran>}.rtp
    % e.g. allfov_era_airicrad_d2019093_183.rtp
    outfilename = sprintf('%s_%s_%s_d%s_%s.rtp', 