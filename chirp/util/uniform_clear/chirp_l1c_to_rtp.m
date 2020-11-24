function [hd0, pd0] = chirp_l1c_to_rtp()
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
addpath /home/sbuczko1/git/rtp_prod2_DEV/chirp      % airs_find_{uniform,clear}


d.home = '/asl/isilon/chirp/chirp_AQ_test3/2018/231/';
d.dir = dir([d.home 'SNDR.SS1330.CHIRP.20180819T*.m06.g*.L1_AQ.std.v02_20.U.*.nc']);

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

% used for concatenating RTP
isfirst = 1;

% assign executables
run_sarta.klayers_exec  = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
run_sarta.sartaclr_exec = '/home/chepplew/gitLib/sarta/bin/chirp_feb20_base_tra_thrm_nte';

klayers_run = [run_sarta.klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               '/home/sbuczko1/LOGS/klayers/klout.txt'];

sarta_run = [run_sarta.sartaclr_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
    ' > /home/sbuczko1/LOGS/sarta/sarta_out.txt'];


% Granule loop for the day
for fn=1:length(d.dir)   % [1:6 8:13 15 17:22 27:29 31:39]
  disp(['fn: ' num2str(fn)])

  [s, a] = read_netcdf_h5([d.dir(fn).folder '/' d.dir(fn).name]);
  junk = strsplit(d.dir(fn).name,'.');
  gran.date = junk{4};
  gran.num  = junk{6};

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
  head.nchan   = length(s.wnum);
  head.ichan   = [1:length(s.wnum)]';
  head.vchan   = s.wnum;
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
  prof.robs1     = s.rad;
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

  % Save file and copy raw rtp data.
  %rtpwrite(fn_rtp1,head,hattr,prof,pattr)

  % ================ clear Subset ===================
  % 1. Get uniform scene subset

  %[iuniform, amax_keep] = cris_find_uniform(head, prof, uniform_cfg);
  [dbtun,  mbt, amax] = chirp_find_uniform(head, prof);

  iuniform = find(abs(mbt) < 1.0);
  nuniform = length(iuniform);
  if 0 == nuniform
    fprintf(2,['>> No uniform FOVs found for granule %d. ' ...
              'SKIPPING\n'],fn)
    continue;
  end

  fprintf(1, '>> Uniform obs found: %d/12150\n', nuniform);
  pdu = rtp_sub_prof(prof,iuniform);

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

  % save a copy for comparison later
  %sav_dir = '/home/chepplew/data/rtp/chirp_AQ/clear/2018/';
  %sav_fn  = ['era_chirp_' gran.date '_' gran.num '_clear.rtp'];
  %rtpwrite([sav_dir sav_fn],hd3,hattr,pdu,pattr)

  nobs = length(pdu.rtime);
  %[iflagsc, bto1232, btc1232] = find_clear_cris_mr(head, prof, 1:nobs);
  [iflagsc, bto1232, btc1232] = chirp_find_clear(hd3, pdu, 1:nobs);

  iclear_all = find(iflagsc == 0);
  iclear_sea = find(iflagsc == 0 & pdu.landfrac == 0);
  iclear = iclear_sea;
  nclear = length(iclear);
  fprintf(1, '>>>> Total of %d clear & uniform obs passed test\n', nclear);
  if 0 == nclear
    fprintf(2,['>> No clear FOVs found for granule %d. ' ...
              'SKIPPING\n'],fn)
    continue;
  end

  prof_clr = rtp_sub_prof(pdu, iclear);

  if isfirst
    pd0  = prof_clr;
    hd0  = hd3;
  else
    % concatenate new random rtp data into running random rtp structure
    [hd0, pd0] = cat_rtp_clh(hd0, pd0, hd3, prof_clr);
  end

  isfirst = 0;
  hdfml('closeall')

end



%{
[ix,iy] = seq_match(fcris_mr,hdc.vchan);
clf;plot(hdc.vchan, rad2bt(hdc.vchan, nanmean(pdc.robs1,2)),'.-')
hold on; plot(fcris_mr(iy), rad2bt(fcris_mr(ix), nanmean(pdc.rclr(iy,:),2)),'.-')

btc = rad2bt(fcris_mr(ix), nanmean(pdc.rclr(iy,:),2));
bto = rad2bt(hdc.vchan, nanmean(pdc.robs1,2));
btbias=bto(1:end-4) - btc(5:end);

%}
