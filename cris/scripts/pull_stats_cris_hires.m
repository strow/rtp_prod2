function pull_stats_cris_hires(year);

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
[n1,n2,n3,userLW,userMW,userSW, ichan] = cris_hires_chans();
f = cris_vchan(2, userLW, userMW, userSW);

sSubset = 'clear';

basedir = fullfile('/asl/data/rtp_cris_ccast_hires', [sSubset '_daily'], ...
                   int2str(year));
dayfiles = dir(fullfile(basedir, ['rtp*_' sSubset '.rtp']));

iday = 1;
% for giday = 1:50:length(dayfiles)
for giday = 1:length(dayfiles)
   fprintf(1, '>>> year = %d  :: giday = %d\n', year, giday);
   a = dir(fullfile(basedir,dayfiles(giday).name));
   if a.bytes > 100000
      [h,ha,p,pa] = rtpread(fullfile(basedir,dayfiles(giday).name));
% Subset here if needed
%**************************************************
% the following line is the majority of the business
% logic here. this line will change frequently: can we
% encapsulate so that this change does not require
% editing this file (thinking something like function
% pointer in C?)
%**************************************************
      k = find( abs(p.rlat) < 30 & p.landfrac == 0 & (p.xtrack == ...
                                                      15 | p.xtrack == 16) & p.solzen > 90);
      sDescriptor = 'all';
      
      p = rtp_sub_prof(p, k);
      for z = 1:9  % loop over FOVs to further sub-select
         ifov = find(p.ifov == z);
         p2 = rtp_sub_prof(p, ifov);
% Loop over obs in day
% Radiance mean and std
         r  = p2.robs1;
         rc = p2.rcalc;
% Convert r to rham
         r = box_to_ham(r);  % assumes r in freq order!!
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
      end  % ifov (z)
      iday = iday + 1
   end % if a.bytes > 1000000
end  % giday
eval_str = ['save ~/testoutput/rtp_cris_hires'  int2str(year) '_' ...
            sSubset '_' sDescriptor  ' btobs btcal bias bias_std *_mean count '];
eval(eval_str);
