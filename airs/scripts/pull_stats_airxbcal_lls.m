function pull_stats_airxbcal_lls(year, filter);

%**************************************************
% need to make this work on daily concat files: look for loop over
% granules, this will need to be removed. Also break out by fov
% (add loop and index over p.ifov)
%
% following the 'file in; file out' standard, this routine will
% read in ONE daily concatenated rtp file and calculate its
% stats. There will be a driver function above this that will feed
% rtp file paths to this routine and can provide for slurm indexing
% and chunking
%**************************************************

%year = 2014;

addpath /asl/matlib/h4tools
addpath /asl/rtp_prod/airs/utils
addpath /asl/packages/ccast/motmsc/utils/
addpath ~/git/rtp_prod2/util
addpath /asl/rtp_prod/cris/unapod

% Get proper frequencies for these data
%**************************************************
% where to get AIRS proper freqs???
%**************************************************
% $$$ [n1,n2,n3,userLW,userMW,userSW, ichan] = cris_lowres_chans();
% $$$ f = cris_vchan(2, userLW, userMW, userSW);

basedir = fullfile('/asl/data/rtp_airxbcal_v5/', ...
                   int2str(year), 'clear');
dayfiles = dir(fullfile(basedir, 'era_airxbcal*_clear.rtp'));
% $$$ basedir = fullfile('/home/sbuczko1/testoutput/airxbcal_ps_test');
% $$$ dayfiles = dir(fullfile(basedir, 'era_airxbcal*.rtp'));

fprintf(1,'>>> numfiles = %d\n', length(dayfiles));

cstr =[ 'bits1-4=NEdT[0.08 0.12 0.15 0.20 0.25 0.30 0.35 0.4 0.5 0.6 0.7' ...
  ' 0.8 1.0 2.0 4.0 nan]; bit5=Aside[0=off,1=on]; bit6=Bside[0=off,1=on];' ...
  ' bits7-8=calflag&calchansummary[0=OK, 1=DCR, 2=moon, 3=other]' ];

iday = 1;
% for giday = 1:50:length(dayfiles)
for giday = 1:length(dayfiles)
   fprintf(1, '>>> year = %d  :: giday = %d\n', year, giday);
   a = dir(fullfile(basedir,dayfiles(giday).name));
   if a.bytes > 100000
      [h,ha,p,pa] = rtpread(fullfile(basedir,dayfiles(giday).name));
      f = h.vchan;  % AIRS proper frequencies

      % sanity check on p.robs1 as read in. (There have been
      % instances where this array is short on the spectral
      % dimension which fails in rad2bt. We trap for this here)
      obs = size(p.robs1);
      chans = size(f);
      if obs(1) ~= chans(1)
          fprintf(2, ['**>> ERROR: obs/vchan spectral channel ' ...
                      'mismatch in %s. Bypassing day.\n'], dayfiles(giday).name);
          continue;
      end
      
      switch filter
        case 1
          k = find(p.iudef(4,:) == 68); % descending node (night)
          sDescriptor='_desc';
        case 2
          k = find(p.iudef(4,:) == 68 & p.landfrac == 0); % descending node
                                                         % (night), ocean
          sDescriptor='_desc_ocean';
        case 3
          k = find(p.iudef(4,:) == 68 & p.landfrac == 1); % descending node
                                                        % (night), land
          sDescriptor='_desc_land';
        case 4
          k = find(p.iudef(4,:) == 65); % ascending node (night)
          sDescriptor='_asc';
        case 5
          k = find(p.iudef(4,:) == 65 & p.landfrac == 0); % ascending node
                                                         % (night), ocean
          sDescriptor='_asc_ocean';
        case 6
          k = find(p.iudef(4,:) == 65 & p.landfrac == 1); % ascending node
                                                        % (night), land
          sDescriptor='_asc_land';
        case 7
          k = find(p.iudef(4,:) == 68 & abs(p.rlat) < 30 & p.landfrac == 0); % tropical
                                                        % ocean
          sDescriptor='_tropocean_night';
        case 8
          k = find(p.iudef(4,:) == 65 & abs(p.rlat) < 30 & p.landfrac == 0); % tropical
                                                        % ocean
          sDescriptor='_tropocean_day';
        case 9
          k = find((p.xtrack >= 43 & p.xtrack <= 48) &...
                   p.iudef(4,:) == 68 & abs(p.rlat) < 30 & p.landfrac == 0); % tropical
                                                        % ocean, near-nadir
          sDescriptor='_tropocean_nadir_night';
        case 10
          k = find((p.xtrack >= 43 & p.xtrack <= 48) &...
                   p.iudef(4,:) == 65 & abs(p.rlat) < 30 & p.landfrac == 0); % tropical
                                                        % ocean, near-nadir
          sDescriptor='_tropocean_nadir_day';
      end

      p = rtp_sub_prof(p, k);

% Initialize counts
      [nedt,ab,ical] = calnum_to_data(p.calflag,cstr);
      n = length(p.rlat);
      count_all = ones(2378,n);
      for i=1:2378
         % Find bad channels
         k = find( p.robs1(i,:) == -9999 | ical(i,:) ~= 0 | nedt(i,:) > 1);
%          % These are the good channels
%          kg = setdiff(1:n,k);
% NaN's for bad channels
         p.robs1(i,k) = NaN;
         p.rcalc(i,k) = NaN;
         count_all(i,k) = 0;
      end
      count(iday,:) = sum(count_all,2)';
      
% Loop over obs in day
% Radiance mean and std
         r  = p.robs1;
         rc = p.rcalc;

% B(T) bias mean and std
         bto = real(rad2bt(f,r));
         btc = real(rad2bt(f,rc));
         btobs(iday,:) = nanmean(bto,2);
         btcal(iday,:) = nanmean(btc,2);
         bias(iday,:)  = nanmean(bto-btc,2);
         bias_std(iday,:) = nanstd(bto-btc,0,2);
         lat_mean(iday) = nanmean(p.rlat);
         lon_mean(iday) = nanmean(p.rlon);
         solzen_mean(iday) = nanmean(p.solzen);
         rtime_mean(iday)  = nanmean(p.rtime);
%         count(iday) = length(p.rlat);
         stemp_mean(iday) = nanmean(p.stemp);
%         iudef4_mean(iday) = nanmean(p.iudef(4,:));
      iday = iday + 1
   end % if a.bytes > 1000000
end  % giday
eval_str = ['save ~/testoutput/rtp_airxbcal'  int2str(year) ...
            '_clear' sDescriptor ' btobs btcal bias bias_std *_mean count '];
eval(eval_str);
