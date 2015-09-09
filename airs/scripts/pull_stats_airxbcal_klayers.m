function pull_stats_airxbcal_klayers(year, filter);

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
% addpath /asl/packages/ccast/motmsc/utils/
addpath ~/git/rtp_prod2/util
% addpath /asl/rtp_prod/cris/unapod
addpath /home/sergio/MATLABCODE/PLOTTER  %
                                         % equal_area_spherical_bands
addpath /asl/matlib/rtptools  % mmwater_rtp.m

klayers_exec = ['/asl/packages/klayersV205/BinV201/' ...
                'klayers_airs_wetwater'];

% Get proper frequencies for these data
%**************************************************
% where to get AIRS proper freqs???
%**************************************************
% $$$ [n1,n2,n3,userLW,userMW,userSW, ichan] = cris_lowres_chans();
% $$$ f = cris_vchan(2, userLW, userMW, userSW);

[sID, sTempPath] = genscratchpath();

basedir = fullfile('/asl/data/rtp_airxbcal_v5/', ...
                   int2str(year), 'clear');
dayfiles = dir(fullfile(basedir, 'era_airxbcal*_clear.rtp'));
fprintf(1,'>>> numfiles = %d\n', length(dayfiles));

% calculate latitude bins
nbins=20; % gives 2N+1 element array of lat bin boundaries
latbins = equal_area_spherical_bands(nbins);
nlatbins = length(latbins);

iday = 1;
% for giday = 1:50:length(dayfiles)
for giday = 1:length(dayfiles)
   fprintf(1, '>>> year = %d  :: giday = %d\n', year, giday);
   a = dir(fullfile(basedir,dayfiles(giday).name));
   if a.bytes > 100000
      [h,ha,p,pa] = rtpread(fullfile(basedir,dayfiles(giday).name));
      f = h.vchan;  % AIRS proper frequencies

      % run klayers on the rtp data (Sergio is asking for this to
      % convert levels to layers for his processing?)
      fprintf(1, '>>> running klayers... ');
      fn_rtp1 = fullfile(basedir,dayfiles(giday).name);
      fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);
      klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ...
                     ' > ' sTempPath '/kout.txt'];
      unix(klayers_run);
      [h,ha,p,pa] = rtpread(fn_rtp2);
      fprintf(1, 'Done\n');

      % get column water
      mmwater = mmwater_rtp(h, p);
      
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
        case 8
          k = find(abs(p.satzen) < 10 & p.solzen > 90 & p.landfrac ...
                   == 0);
          % ascending (night), ocean, near nadir
          sDescriptor='_asc_ocean_nadir';
        case 9
          k = find(abs(p.satzen) < 10 & p.solzen < 90 & p.landfrac ...
                   == 0);
          % descending (day), ocean, near nadir
          sDescriptor='_desc_ocean_nadir';
      end

      pp = rtp_sub_prof(p, k);
      mmwater = mmwater(k);
      
      % Loop over latitude bins
      for ilat = 1:nlatbins-1
          % subset based on latitude bin
          inbin = find(pp.rlat > latbins(ilat) & pp.rlat <= ...
                     latbins(ilat+1));
          p = rtp_sub_prof(pp,inbin);
          binwater = mmwater(inbin);
          
% Radiance mean and std
         r  = p.robs1;
         rc = p.rcalc;

% B(T) bias mean and std
         bto = real(rad2bt(f,r));
         btc = real(rad2bt(f,rc));
         btobs(iday,ilat,:) = nanmean(bto,2);
         btcal(iday,ilat,:) = nanmean(btc,2);
         bias(iday,ilat,:)  = nanmean(bto-btc,2);
         bias_std(iday,ilat,:) = nanstd(bto-btc,0,2);
         lat_mean(iday,ilat) = nanmean(p.rlat);
         lon_mean(iday,ilat) = nanmean(p.rlon);
         solzen_mean(iday,ilat) = nanmean(p.solzen);
         rtime_mean(iday,ilat)  = nanmean(p.rtime);
         count(iday,ilat) = length(p.rlat);
         stemp_mean(iday,ilat) = nanmean(p.stemp);
         ptemp_mean(iday,ilat,:) = nanmean(p.ptemp,2);
         gas1_mean(iday,ilat,:) = nanmean(p.gas_1,2);
         gas3_mean(iday,ilat,:) = nanmean(p.gas_3,2);
         spres_mean(iday,ilat) = nanmean(p.spres);
         nlevs_mean(iday,ilat) = nanmean(p.nlevs);
         iudef4_mean(iday,ilat) = nanmean(p.iudef(4,:));
         mmwater_mean(iday,ilat) = nanmean(binwater);
         satzen_mean(iday,ilat) = nanmean(p.satzen);
         plevs_mean(iday,ilat,:) = nanmean(p.plevs,2);
         end  % end loop over latitudes
         iday = iday + 1
   end % if a.bytes > 1000000
end  % giday
% $$$ eval_str = ['save ~/testoutput/rtp_airxbcal'  int2str(year) ...
% $$$             '_rand' sDescriptor ' btobs btcal bias bias_std *_mean count '];
eval_str = ['save ~/testoutput/rtp_airxbcal_kl'  int2str(year) ...
            '_clear' sDescriptor ' btobs btcal bias bias_std *_mean count latbins'];
eval(eval_str);
