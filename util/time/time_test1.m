%
% time_test1 -- show internal start times for RDR and GCRSO files
% 

addpath ../source
addpath utils

rid = 'test file';

% rdr_dir = '/asl/data/cris/ccast/rdr60/2012/365';
% geo_dir = '/asl/data/cris/sdr60/hdf/2012/365';
% rdr_mat =       'RDR_d20121230_t0007312.mat';
% geo_hdf = 'GCRSO_npp_d20121230_t0007379_e0015357_b06081_c20121230061531751107_noaa_ops.h5';

rdr_dir = '/asl/data/cris/ccast/rdr60/2014/091';
geo_dir =   '/asl/data/cris/sdr60/hdf/2014/091';

rdr_mat =       'RDR_d20140401_t0001492.mat';
geo_hdf = 'GCRSO_npp_d20140401_t0001539_e0009517_b12564_c20140401060949177768_noaa_ops.h5';

rdr_file = fullfile(rdr_dir, rdr_mat);
geo_file = fullfile(geo_dir, geo_hdf);

% RDR to SDR time offset
dtRDR = 2817 + 4 * 8000;

% load and check matlab RDR data
load(rdr_file)
[igmLW, igmMW, igmSW, igmTime, igmFOR, igmSDR] = checkRDR(d1, rid);
fprintf(1, 'first rdr internal time %s\n', ...
        datestr(utc2dnum(igmTime(1,1)/1000)));

% load the geo data
[geo, agatt, attr4] = read_GCRSO(geo_file);
fprintf(1, 'first geo internal time %s\n', ...
        datestr(iet2dnum(double(geo.FORTime(1,1)))));

