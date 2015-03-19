set_process_dirs
addpath(genpath(rtp_sw_dir));

sfile = '/asl/data/cris/ccast/sdr60_hr/2013/240/SDR_d20130828_t1246546.mat';
create_cris_ccast_hires_rtp(sfile, 'test.rtp');