addpath ~/git/swutils
addpath ~/git/matlib/clouds/sarta
addpath ~/git/rtp_prod2_DEV/util
addpath ~/git/rtp_prod2_DEV/emis
addpath ~/git/rtp_prod2_DEV/grib
% addpath ~/git/rtp_prod2_DEV/util/time
addpath ~/git/rtp_prod2_DEV/airs
addpath ~/git/rtp_prod2_DEV/airs/readers
addpath ~/git/rtp_prod2_DEV/airs/util
addpath ~/git/matlib/rtptools
addpath ~/git/matlib/aslutil
addpath /asl/matlib/time

cfg.model='era';
cfg.fovlist=[1:90]
cfg.klayers_exec='/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
cfg.sartaclr_exec='/home/chepplew/gitLib/sarta/bin/airs_l1c_2834_may19_prod';
cfg.sartacld_exec='/home/chepplew/gitLib/sarta/bin/airs_l1c_2834_cloudy_may19_prod';

inpath='/asl/data/airs/L1C_v672/2019/018';

[h,ha,p,pa] = create_airicrad_random_day_rtp(inpath,cfg);
