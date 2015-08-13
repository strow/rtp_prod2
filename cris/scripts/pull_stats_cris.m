%**************************************************
% need to make this work on dialy concat files: look for loop over
% granules, this will need to be removed. Also break out by fov
% (add loop and index over p.ifov)
%**************************************************

addpath /asl/matlib/h4tools
addpath /asl/rtp_prod/airs/utils
%addpath /asl/packages/ccast/motmsc/utils/
addpath ~/Git/ccast/motmsc/utils/
addpath ~/Git/rtp_prod2/util
addpath ~/Matlab/FileExchange
addpath   /asl/rtp_prod/cris/unapod

% high, low limits for xtrack
% lx = 12; hx = 17; 

% Generate doy list used to check output of glob
for i=1:366
   doy(i,:) = sprintf('%03.0f',i);
end

% Get proper frequencies for these data
[n1,n2,n3,userLW,userMW,userSW, ichan] = cris_lowres_chans();
f = cris_vchan(2, userLW, userMW, userSW);

for iyear = 2012
% CCAST rtp clear
%   fdir = ['/asl/data/rtp_cris_ccast_lowres/' int2str(iyear) '/clear/'];
   fdir = ['/asl/data/rtp_cris_ccast_lores/clear/' int2str(iyear) ];

   % Get only 3-digit directory names from 001 to 366
   %**************************************************
   % glob comes from matlab exchange: need to make this a generally
   % available function in the ASL sphere (or can we simplify the
   % logic and do this with native matlab functions?)
   % http://www.mathworks.com/matlabcentral/fileexchange/40149-expand-wildcards-for-files-and-directory-names
   %
   % list contains an array of path strings leading to
   % fdir/iyear/doy/
   % This is just an internal implementation of my path driver files
   %**************************************************
   [list,~] = glob([fdir '/???/']);

%   keyboard
   list = cell2mat(list);  % Cells to strings
% Pull out ddd part of name
   list = list(:,length(fdir)+2:end-1);
   gooddaydir = ismember(list,doy,'rows');
% Indices of good day directories (usually all entries in list)
   daydirs = find(gooddaydir);
   %**************************************************
   % this loop has to be refactored. since we will draw form the
   % daily concat file, this loop over granules does not need to
   % exist. We will need a loop over fov, though
   %**************************************************
   for iday_index = 1:length(daydirs)
      iday = daydirs(iday_index)
% List of granules for the day
      fdir = ['/asl/data/rtp_cris_ccast_lores/clear/' int2str(iyear) '/' list(iday,:)];
      a = dir(fullfile(fdir,'*.rtp'));
% Get daily average
% Initialize mean, std running mean (per day)
%  m_init  = zeros(1,2223); 
      m_init  = zeros(1,1317); 
      m   = m_init; w   = m_init; n   = m_init;
      mo  = m_init; wo  = m_init; no  = m_init;
      mc  = m_init; wc  = m_init; nc  = m_init;
      mco = m_init; wco = m_init; nco = m_init;
      mb  = m_init; wb  = m_init; nb  = m_init;
      mt = 0;       wt = 0;       nt = 0;
      for i=1:length(a);  % Loop over granules
         if a(i).bytes > 21509  % Length of rtp if no scenes
            [h,ha,p,pa] = rtpread(fullfile(fdir,a(i).name));
            % Subset here if needed
            
            %**************************************************
            % the following line is the majority of the business
            % logic here. this line will change frequently: can we
            % encapsulate so that this change does not require
            % editing this file (thinking something like function
            % pointer in C?)
            %**************************************************
            k = find( abs(p.rlat) < 30 & p.landfrac == 0 & (p.xtrack == 15 | p.xtrack == 16) & p.solzen > 90);
            if length(k) >= 2       % tropical granule over ocean
               p = rtp_sub_prof(p, k);
% Loop over obs in granule
               for j=1:length(p.rlat)
% Radiance mean and std
                  r  = p.robs1(:,j)';
                  rc = p.rcalc(:,j)';
% Convert r to rham
                  r = box_to_ham(r');  % assumes r in freq order!!
                  r = r';
% Recursive mean and std for robs, rcal
                  [m, w, n] = rec_var(m,w,n,r);
                  [mc, wc, nc] = rec_var(mc,wc,nc,rc);
% B(T) bias mean and std
                  btobs = real(rad2bt(f,r));
                  btcal = real(rad2bt(f,rc));
                  bias  = btobs-btcal;
% Recursive mean and std for bias
                  [mb, wb, nb] = rec_var(mb,wb,nb,bias);
% Recursive mean and std for rtime
                  [mt, wt, nt] = rec_var(mt,wt,nt,p.rtime(j));
               end  % loop over obs in granule
               lat_mean = nanmean(p.rlat);
               lon_mean = nanmean(p.rlon);
               solzen_mean = nanmean(p.solzen);
               rtime_mean  = nanmean(p.rtime);
            end  % Tropical
         end  % Good granule if then structure
      end   % Granule loop
      rvar              = w ./ (n - 1);
      rstd(iday,:)      = sqrt(rvar);
      rmean(iday,:)     = m;
      rcalmean(iday,:)  = mc;

      bvar              = wb ./ (nb -1);
      bias_std(iday,:)  = sqrt(bvar);
      bias_mean(iday,:) = mb;
      all_rtime(iday)   = mt;
      
      all_rlat(iday)    = lat_mean;
      all_rlon(iday)    = lon_mean;
      all_solzen(iday)  = solzen_mean;
      all_count(iday)   = nanmean(n);
   end  % Day loop
   eval_str = ['save ~/Desktop/rtp_cris_hires'  int2str(iyear)  ' rmean rcalmean bias_mean  bias_std rstd  all_*'];
   eval(eval_str);
end  % Year loop


%             w  = zeros(1,2223); n  = zeros(1,2223);
%             mb = zeros(1,2223); wb = zeros(1,2223); nb = zeros(1,2223);
%             mc = zeros(1,2223); wc = zeros(1,2223); nc = zeros(1,2223);
