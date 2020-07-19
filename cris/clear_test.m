%% testing script for uniform clear filter. tests all flavors:
%% lowres, hires, interpolated hires with a common granule

addpath /home/sbuczko1/git/rtp_prod2_DEV/cris/readers
addpath /home/sbuczko1/git/rtp_prod2_DEV/cris/util/uniform_clear
addpath /home/sbuczko1/git/rtp_prod2_DEV/cris/util/
addpath /home/sbuczko1/git/rtp_prod2_DEV/util/time

% using granule 09/01/2018 098 (found via NASA EarthData search
% tool: https://search.earthdata.nasa.gov/search/)
lowresinpath = '/asl/cris/ccast/sdr45_npp_LR/2018/244/CrIS_SDR_npp_s45_d20180901_t0942080_g098_v20a.mat';
hiresinpath = '/asl/cris/ccast/sdr45_npp_HR/2018/244/CrIS_SDR_npp_s45_d20180901_t0942080_g098_v20a.mat';

%% Lowres  and hires interpolated to lowres (will use lowres sarta)
cfg = struct;
cfg.klayers_exec = ['/asl/packages/klayersV205/BinV201/' ...
                    'klayers_airs_wetwater'];
cfg.sartaclr_exec = '/asl/bin/sarta_crisg4_nov09_wcon_nte';
cfg.nguard = 2;
cfg.nsarta = 4;

% read in granule for LR
[hLR, haLR, pLR, paLR] = ccast2rtp(lowresinpath, cfg.nguard, ...
                                   cfg.nsarta);
% run uniform filter test
uniform_cfg = struct;
uniform_cfg.uniform_test_channel = 961;
uniform_cfg.uniform_bt_threshold = 0.4; 
[iuniformLR, amax_keepLR, amaxLR] = cris_find_uniform(hLR, pLR, uniform_cfg);

% read in granule for HR interpolated down to LR
[hHL, haHL, pHL, paHL] = ccast2rtp_hi2lo(hiresinpath, cfg.nguard, ...
                                             cfg.nsarta);
% run uniform filter test
[iuniformHL, amax_keepHL, amaxHL] = cris_find_uniform(hHL, pHL, uniform_cfg);

%% Hires
% change to hires cris sarta
cfg.sartaclr_exec = '/asl/bin/crisg4_oct16';
% read in hires granule
[hHR, haHR, pHR, paHR] = ccast2rtp(hiresinpath, cfg.nguard, cfg.nsarta);
% run uniform filter test
[iuniformHR, amax_keepHR, amaxHR] = cris_find_uniform(hHR, pHR, uniform_cfg);





