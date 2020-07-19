function [keep2D,keep_ind] = hha_lat_subsample_equal_area3(head0,prof0)

% based on hha_rand.m
% same as hha_lat_subsample_equal_area2.m except it can take ARB size input profs

% lat_subsample_equal_area(lat);
%
% Inputs:  head,prof : structure containing rlat,tlon,atrack,xtrack etc
%          ASSUMES prof has allfov 12150 (90x135) data
% Output:  keep2D     : indices 2D matrix of input vector (xtrack,atrack) to keep
%          keep_ind : changing those 2d indices into one that indexes (1x12150)
%
addpath /asl/packages/ccast/motmsc/time
addpath /asl/matlib/rtptools/

head = head0;
prof = prof0;

% Pick a time for initializing random number generator
tai = prof.rtime(1);

% Nice changing random seed
rand('seed',tai(1,1));  % random selection initialization.

% Pick a nominal latitude, longitude
lon2 = prof.rlon;
lat2 = prof.rlat;

% Initialize reason since same FOV can be picked for different
% reasons, it has to be updated from a starting point
reason = uint16(zeros(size(lon2))); 
sza   = prof.satzen;

% Each granule should have 135*6=810 near nadir spectra

% Now the selection
vx = find(abs(sza)<1.5); % find all near nadir spectra
vx = find(abs(sza)<3.5); % find all near nadir spectra

%%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%%%         start modification to HHA code
%%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

iFlip = -1;            %% assume you can just stick to HHA orig algorithm
iForwardBackward = +1; %% dont have to worry about first part of granule vs last part of granule

i46 = find(prof.xtrack == 46);
dadiff = diff(lat2(i46));
junk = find(dadiff > 0);  positive(junk) = +1;
junk = find(dadiff <= 0); positive(junk) = -1;
lat20 = lat2;
meanlat0 = nanmean(lat2(:));
numAtrack = 135;

if (length(find(positive > 0)) ~= length(dadiff)) & (length(find(positive < 0)) ~= length(dadiff))
  iFlip = +1;
  disp(' <<< polar granule >>> ');
  startpositive = positive(1);
  numAtrack = find(positive ~= startpositive,1);

  centerlat = lat2(i46);
  numBtrack = find(abs(centerlat) <= 78);

  junk = find(numBtrack <= numAtrack);
  numAtrack = max(numBtrack(junk));

  if length(numAtrack) == 1
    %%% things were fine, we had enough data before getting to |rlat| == 78
    iForwardBackward = +1;	
    indstop = numAtrack*90;
    [head,prof] = subset_rtp(head,prof,[],[],1:indstop);
    lon2 = prof.rlon;
    lat2 = prof.rlat;
    reason = uint16(zeros(size(lon2))); 
    sza   = prof.satzen;
  else
    %%% oops no data from beginning of gran to |rlat| == 78, so look at END of granule at subset
    iForwardBackward = -1;	  
    numAtrack = min(numBtrack);
    indstop = numAtrack*90+1;
    [head,prof] = subset_rtp(head,prof,[],[],indstop:length(prof.rlon));
    lon2 = prof.rlon;
    lat2 = prof.rlat;
    reason = uint16(zeros(size(lon2))); 
    sza   = prof.satzen;
    minAtrack = min(prof.atrack);
  end
  vx = find(abs(sza)<3.5); % find all near nadir spectra

  blat2 = lat2;
  
  fprintf(1,'  changed mean lat from %8.6f to %8.6f; numAtrack now %3i \n',meanlat0,nanmean(blat2(:)),numAtrack)
else
  blat2 = lat2;
end

%%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%%%         end modification to HHA code
%%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

%%% back to HHA algorithm

sn = size(vx,1);
sn = length(vx);
% This is key randomly permute the near nadir ID's.
vxr = vx(randperm(sn));

% Subset these near nadir by cos(lat of gran mean).
if iFlip > 0
  nsave0 = floor(sn*abs(cos(nanmean(lat20(:))/57.3))+0.5);
end
nsave = floor(sn*abs(cos(nanmean(blat2(:))/57.3))+0.5);

if iFlip > 0
  fprintf(1,'<lat> = %8.6f : orig nsave = %3i, final nsave = %3i -- will reduce by 1/6 \n',nanmean(blat2(:)),nsave0,nsave)
  nsave = min(nsave,nsave0);
else
  fprintf(1,'<lat> = %8.6f : nsave = %3i -- will reduce by 1/6 \n',nanmean(blat2(:)),nsave)
end

if abs(mean(blat2(:))) > 30
  PX = [-6.781163592359652e-06     8.826415250236825e-04    -3.817478053811275e-02     1.534451094844683e+00];
  adj_factor = polyval(PX,abs(mean(blat2(:))));
  fprintf(1,'     *** *** *** adjusting nsave by factor %8.6f \n',adj_factor);
  nsave = ceil(nsave * adj_factor);
end

% This leads to too many random, so pick every 6th one
% Remember vxr is already randomized so this is OK
vc = vxr(1:6:nsave); 

% Set the reason flag
reason(vc) = bitset(reason(vc),4);
site_id(vc) = 88;

keep2D(:,1) = mod(vc-1,90) + 1;
keep2D(:,2) = idivide(int32(vc-1),int32(90)) + 1;   %% integer division
keep_ind = vc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Done, now see what we have
iPlot = -1;
if iPlot > 0
  figure(1); clf; plot(lat2(46,:)); title(num2str(mean(lat20(:))));
  figure(2); clf; plot(blat2(46,:)); title(num2str(mean(blat2(:))));

  figure(3); clf
  imagesc(sza'); colorbar; title('colorbar = sza')
  hold on;
  line([45.5 45.5],[0 numAtrack],'color','k','linewidth',2);
  line([43 43],[0 numAtrack],'color','k');
  line([48 48],[0 numAtrack],'color','k');
  [ii,jj]=ind2sub([90 numAtrack],vc);
  plot(ii,jj,'ro')
  hold off
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
