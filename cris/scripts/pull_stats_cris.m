function pull_stats_cris(year, filter);

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
[n1,n2,n3,userLW,userMW,userSW, ichan] = cris_lowres_chans();
f = cris_vchan(2, userLW, userMW, userSW);

basedir = fullfile('/asl/data/rtp_cris_ccast_lowres/random_daily', ...
                   int2str(year));
dayfiles = dir(fullfile(basedir, 'rtp*_random.rtp'));

iday = 1;
% for giday = 1:50:length(dayfiles)
for giday = 1:length(dayfiles)
   fprintf(1, '>>> year = %d  :: giday = %d\n', year, giday);
   a = dir(fullfile(basedir,dayfiles(giday).name));
   if a.bytes > 100000
      [h,ha,p,pa] = rtpread(fullfile(basedir,dayfiles(giday).name));

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
      end

      p = rtp_sub_prof(p, k);
      for z = 1:9  % loop over FOVs to further sub-select
         ifov = find(p.ifov == z);
         p2 = rtp_sub_prof(p, ifov);
% Loop over obs in day
% Radiance mean and std
         r  = p2.robs1;
         rc = p2.rcalc;
% Convert r to rham
         r = box_to_ham(r);  % assumes r in freq order!!  Needed
                             % for lowres
% B(T) bias mean and std
         bto = real(rad2bt(f,r));
         btc = real(rad2bt(f,rc));
         btobs(iday,:,z) = nanmean(bto,2);
         btcal(iday,:,z) = nanmean(btc,2);
         bias(iday,:,z)  = nanmean(bto-btc,2);
         bias_std(iday,:,z) = nanstd(bto-btc,0,2);
         lat_mean(iday,z) = nanmean(p2.rlat);
         lon_mean(iday,z) = nanmean(p2.rlon);
         solzen_mean(iday,z) = nanmean(p2.solzen);
         rtime_mean(iday,z)  = nanmean(p2.rtime);
         count(iday,z) = length(p2.rlat);
         stemp_mean(iday,z) = nanmean(p2.stemp);
         iudef4_mean(iday,z) = nanmean(p2.iudef(4,:));
      end  % ifov (z)
      iday = iday + 1
   end % if a.bytes > 1000000
end  % giday
eval_str = ['save ~/testoutput/rtp_cris_lowres'  int2str(year) ...
            '_random' sDescriptor ' btobs btcal bias bias_std *_mean count '];
eval(eval_str);
