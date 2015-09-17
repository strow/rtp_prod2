function pull_stats_airxbcal(year, filter);

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

% $$$ basedir = fullfile('/asl/data/rtp_airxbcal_v5/', ...
% $$$                    int2str(year), 'random');
% $$$ dayfiles = dir(fullfile(basedir, 'era_airxbcal*_rand.rtp'));
basedir = fullfile('/home/sbuczko1/testoutput/airxbcal_ps_test');
dayfiles = dir(fullfile(basedir, 'era_airxbcal*.rtp'));

fprintf(1,'>>> numfiles = %d\n', length(dayfiles));

iday = 1;
% for giday = 1:50:length(dayfiles)
for giday = 1:length(dayfiles)
   fprintf(1, '>>> year = %d  :: giday = %d\n', year, giday);
   a = dir(fullfile(basedir,dayfiles(giday).name));
   a.bytes
   if a.bytes > 100000
      [h,ha,p,pa] = rtpread(fullfile(basedir,dayfiles(giday).name));
      f = h.vchan;  % AIRS proper frequencies
      
      switch filter
        case 1
          k = find(p.iudef(4,:) == 1); % descending node (night)
          sDescriptor='_desc';
        case 2
          k = find(p.iudef(4,:) == 1 & p.landfrac == 0); % descending node
                                                         % (night), ocean
          sDescriptor='_desc_ocean';
        case 3
          k = find(p.iudef(4,:) == 1 & p.landfrac == 1); % descending node
                                                        % (night), land
          sDescriptor='_desc_land';
        case 4
          k = find(p.iudef(4,:) == 0); % ascending node (night)
          sDescriptor='_asc';
        case 5
          k = find(p.iudef(4,:) == 0 & p.landfrac == 0); % ascending node
                                                         % (night), ocean
          sDescriptor='_asc_ocean';
        case 6
          k = find(p.iudef(4,:) == 0 & p.landfrac == 1); % ascending node
                                                        % (night), land
          sDescriptor='_asc_land';
        case 7
          k = find(abs(p.rlat) < 30 & p.landfrac == 0); % tropical
                                                        % ocean
          sDescriptor='_tropocean';
      end

      p = rtp_sub_prof(p, k);

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
         count(iday) = length(p.rlat);
         stemp_mean(iday) = nanmean(p.stemp);
         iudef4_mean(iday) = nanmean(p.iudef(4,:));
      iday = iday + 1
   end % if a.bytes > 1000000
end  % giday
eval_str = ['save ~/testoutput/airxbcal_ps_test/rtp_airxbcal'  int2str(year) ...
            '_clear_tropocean_old btobs btcal bias bias_std *_mean count '];
eval(eval_str);
