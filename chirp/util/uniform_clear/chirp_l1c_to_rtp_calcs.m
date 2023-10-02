function [hd0, pd0] = chirp_l1c_to_rtp_calcs()
% chirp_l1c_to_rtp()


% based on ~/projects/sirs/airs_l1c_to_rtp.m
% and /home/sbuczko1/git/rtp_prod2/cris/create_cris_ccast_hires_clear_day_rtp.m

addpath /home/motteler/shome/chirp_test             % read_netcdf_h5
addpath /asl/matlib/rtptools                        % set_attr
addpath /asl/matlib/time
addpath /asl/matlib/aslutil                         % int2bits
addpath /home/sbuczko1/git/rtp_prod2/grib           % fill_era
addpath /home/sbuczko1/git/rtp_prod2/emis           % rtp_add_emis
addpath /home/sbuczko1/git/rtp_prod2/util           % seq_match
addpath /home/sbuczko1/git/rtp_prod2_DEV/chirp/util/uniform_clear      % airs_find_{uniform,clear}
addpath /home/sbuczko1/git/rtp_prod2_DEV/cris/util/uniform_clear % create_airs_scan_from_cris

% $$$ d.home = '/asl/isilon/chirp/chirp_AQ_test4/2018/231/';
% $$$ d.dir = dir([d.home 'SNDR.SS1330.CHIRP.20180819T*.m06.g*.L1_AQ.std.v02_20.U.*.nc']);
d.home = '/asl/isilon/chirp/chirp_J1_test3/2018/231/';
d.dir = dir([d.home 'SNDR.SS1330.CHIRP.20180819T*.m06.g*.L1_J1.std.v02_20.U.*.nc']);

% Initialize
[sID, sTempPath] = genscratchpath();
fn_rtp1 = fullfile(sTempPath, ['chirp_' sID '.rtp']);
fn_rtp2 = fullfile(sTempPath, ['chirp_' sID '_kl.rtp']);
fn_rtp3 = fullfile(sTempPath, ['chirp_' sID '_sar.rtp']);

cfg = struct;
cfg.model = 'era';

uniform_cfg = struct;
uniform_cfg.uniform_test_channel = 961;   % ??? 900 or 1213 cm-1
uniform_cfg.uniform_bt_threshold = 0.4;
uniform_cfg.cscanlines = 45;
uniform_cfg.ascanlines = 135;

% assign executables
run_sarta.klayers_exec  = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
run_sarta.sartaclr_exec = '/home/chepplew/gitLib/sarta/bin/chirp_feb20_base_tra_thrm_nte';

klayers_run = [run_sarta.klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               '/home/sbuczko1/LOGS/klayers/klout.txt'];

sarta_run = [run_sarta.sartaclr_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
    ' > /home/sbuczko1/LOGS/sarta/sarta_out.txt'];

% Granule loop for the day
% used for concatenating RTP
isfirst = 1;
for fn= 1:length(d.dir)  %[1:6 8:13 15 17:22 27:29 31:39] % 1:length(d.dir)
  disp(['fn: ' num2str(fn)])

  [s, a] = read_netcdf_h5([d.dir(fn).folder '/' d.dir(fn).name]);
  junk = strsplit(d.dir(fn).name,'.');
  gran.date = junk{4};
  gran.num  = junk{6};

  % determine source instrument from attributes
  if contains(a.input_file_types, 'CrIS_L1B')
      uniform_cfg.source_instrument = 'cris';
  elseif contains(a.input_file_types, 'AIRS_L1C')
          uniform_cfg.source_instrument = 'airs';
  end

  % just pick a couple of channels for testing (i.e. 961.250 and
  % 1232.500 (indices 499 and 741)
% $$$   ichans = [499 741]';
  ichans = [1:length(s.wnum)]';
  vchans = s.wnum(ichans);

  % Assign Header variables
  head = struct;
  head.pfields = 4;  % robs1, no calcs in file
  head.ptype   = 0;
  head.ngas    = 0;
  % product_name_platform: "SS1330"
  head.instid  = 800; % AIRS
  head.pltfid  = -9999;
  head.ptype   = 0;    % levels
  head.ngas    = 0;
% $$$   head.nchan   = length(s.wnum);
% $$$   head.ichan   = [1:length(s.wnum)]';
% $$$   head.vchan   = s.wnum;
  head.nchan = length(ichans);
  head.ichan = ichans;
  head.vchan = vchans;
  head.vcmax   = max(head.vchan);
  head.vcmin   = min(head.vchan);

  % Assign header attribute strings
  trace = struct;
  trace.githash = 'na';
  trace.RunDate = 'na';
  hattr={ {'header' 'pltfid' 'Aqua'}, ...
        {'header' 'instid' 'CHIRP'}
        {'header' 'githash' trace.githash}, ...
        {'header' 'rundate' trace.RunDate} };

  % Assign Prof variables
  prof = struct;
  prof.findex    = single(a.granule_number)*ones(1,length(s.lat),'single');
  prof.atrack    = single(s.atrack)';
  prof.xtrack    = single(s.xtrack)';
  %prof.zobs      = [];
% $$$   prof.robs1     = s.rad;
  prof.robs1     = s.rad(ichans, :);
  prof.rlat      = s.lat';
  prof.rlon      = s.lon';
  prof.rtime     = airs2tai(s.obs_time_tai93)';
  prof.scanang   = s.view_ang';
  prof.satzen    = s.sat_zen';
  prof.satazi    = s.sat_azi';
  prof.solzen    = s.sol_zen';
  prof.solazi    = s.sol_azi';
  prof.landfrac  = s.land_frac';
  %prof.udef      = [];
  %prof.iudef     = [];

  % Assign attribute strings
  pattr = struct;
  pattr={{'profiles' 'iudef(1,:)' 'Dust flag:[1=true,0=false,-1=land,-2=cloud,-3=bad data]'},...
      {'profiles' 'iudef(2,:)' 'Dust_score:[>380 (probable), N/A if Dust Flag < 0]'},...
      {'profiles' 'iudef(3,:)' 'SceneInhomogeneous:[128=inhomogeneous,64=homogeneous]'},...
      {'profiles' 'iudef(4,:)' 'scan_node_type [0=Ascending, 1=Descending]'},...
      {'profiles' 'udef(1,:)' 'sun_glint_distance:[km to sunglint,-9999=unknown,30000=no glint]'},...
      {'profiles' 'udef(2,:)' 'spectral_clear_indicator:[2=ocean clr,1=ocean n/clr,0=inc. data,-1=land n/clr,-2=land clr]'},...
      {'profiles' 'udef(3,:)' 'BT_diff_SO2:[<-6, likely volcanic input]'},...
      {'profiles' 'udef(4,:)' 'Inhomo850:[abs()>0.84 likely inhomogeneous'},...
      {'profiles' 'udef(5,:)' 'Rdiff_swindow'},...
      {'profiles' 'udef(6,:)' 'Rdiff_lwindow'}};
 
  %%pattr = set_attr(pattr, 'robs1', 'inpath');
  %%pattr = set_attr(pattr, 'rtime', 'TAI:1958');

  % Add in model data ******************************
  fprintf(1, '>>> Add model: %s...', cfg.model)
  switch cfg.model
   case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
   case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
   case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
  end

  head.pfields = 5;  % robs, model

  [prof,pattr] = rtp_add_emis(prof,pattr);

  %[iuniform, amax_keep] = cris_find_uniform(head, prof, uniform_cfg);
  [iuniform,  mbt, amax] = chirp_find_uniform(head, prof, uniform_cfg);

% $$$   iuniform = find(abs(mbt) < 1.0);
  nuniform = length(iuniform);
  if 0 == nuniform
    fprintf(2,['>> No uniform FOVs found for granule %d. ' ...
              'SKIPPING\n'],fn)
    continue;
  end

  fprintf(1, '>> Uniform obs found: %d/12150\n', nuniform);
  pdu = rtp_sub_prof(prof,iuniform);
  clear prof
  rtpwrite(fn_rtp1,head,hattr,pdu,pattr)

  % Now run klayers
  unix(klayers_run);

  %[hdx,~,pdx,~] = rtpread(fn_rtp2);
  % Now run sarta
  unix(sarta_run);

  % Read in new rcalcs and insert into origin pdu field
  %stFileInfo = dir(fn_rtp3);
  [hd3,~,pd3,~] = rtpread(fn_rtp3);
  pdu.rclr  = pd3.rcalc;
  %prof = rmfield(prof,'rcalc');
  %clear p3;
  hd3.pfields = 7;        % includes model, obs & calc
  hd3.ptype   = 0;        % back to model levels (pre-klayers)

  delete(fn_rtp1, fn_rtp2, fn_rtp3);

  if isfirst
    pd0  = pdu;
    hd0  = hd3;
    isfirst = 0;

  else
    % concatenate new random rtp data into running random rtp structure
    pd0 = rtp_cat_prof(pd0, pdu);
  end


end

clear_cfg.clear_test_channel = 961;
clear_cfg.clear_ocean_bt_threshold = 4;
clear_cfg.clear_land_bt_threshold = 7;

nobs = length(pd0.rtime);
[iflagsc, bto, btc] = chirp_find_clear(hd0, pd0, clear_cfg);

iclear_all = find(iflagsc == 0);
iclear_sea = find(iflagsc == 0 & pd0.landfrac == 0);
iclear = iclear_sea;
nclear = length(iclear);
fprintf(1, '>>>> Total of %d clear & uniform obs passed test\n', nclear);
if 0 == nclear
    fprintf(2,['>> No clear FOVs found for granule %d. ' ...
               'SKIPPING\n'],fn)
end

prof_clr = rtp_sub_prof(pd0, iclear);

% produce some plots of ocean clear distributions

% 961 wn
fprintf(1, '>> Plot 961wn dbt for clear subset\n')
ch = 961;
cind = find(hd0.vchan > ch,1);
fprintf(1, '\t using chan %d : %7.3f\n', cind, hd0.vchan(cind));
bto = real(rad2bt(hd0.vchan(cind), prof_clr.robs1(cind,:)));
btc = real(rad2bt(hd0.vchan(cind), prof_clr.rclr(cind,:)));
dbt = bto - btc;
fprintf(1,'>> ch 961 min dbt=%f  max dbt=%f\n', min(abs(dbt)), max(abs(dbt)));
figure
simplemap(prof_clr.rlat, prof_clr.rlon, dbt)
caxis([-4 4])
title('2018/231 chirp clear 961wn ocean')

% 1231 wn
fprintf(1, '>> Plot 961wn dbt for clear subset\n')
ch = 1231;
cind = find(hd0.vchan > ch,1);
fprintf(1, '\t using chan %d : %7.3f\n', cind, hd0.vchan(cind));
bto = real(rad2bt(hd0.vchan(cind), prof_clr.robs1(cind,:)));
btc = real(rad2bt(hd0.vchan(cind), prof_clr.rclr(cind,:)));
dbt = bto - btc;
fprintf(1,'>> ch 1231 min dbt=%f  max dbt=%f\n', min(abs(dbt)), max(abs(dbt)));
figure
simplemap(prof_clr.rlat, prof_clr.rlon, dbt)
caxis([-4 4])
title('2018/231 chirp clear 1231wn ocean')

keyboard

