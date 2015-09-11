function [keep,keep_ind] = hha_lat_subsample_equal_area2_cris_hires(head0,prof0)

% based on hha_rand.m, works for lo or hi res

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% lat_subsample_equal_area(lat);
%
% Inputs:  prof : structure containing rlat,tlon,atrack,xtrack etc
% Output:  keep : indices of input vector (xtrack,atrack) to keep 
%
addpath /asl/packages/ccast/motmsc/time
addpath /asl/matlib/rtptools/

prof00 = prof0;
prof0 = expand_hires_cristrack(prof0);   %% basically just creates "fake" expand_atrack and expand_xtrack

head = head0;
prof = prof0;

% Pick a time for initializing random number generator
tai = prof.rtime(1);

% Nice changing random seed
rand('seed',tai(1,1));  % random selection initialization.

[mm,nn] = size(prof.atrack);

% Pick a nominal latitude, longitude
%lon2 = reshape(prof.rlon,90,180);
%lat2 = reshape(prof.rlat,90,180);
lon2 = prof.rlon;
lat2 = prof.rlat;

% Initialize reason since same FOV can be picked for different
% reasons, it has to be updated from a starting point
reason = uint16(zeros(size(lon2))); 
%sza   = reshape(prof.satzen,90,180);
sza   = prof.satzen;

% Each granule has 60 * (2*(3x3)) * 30 = 16200 spectra, out of which MANY are near nadir spectra
% Each granule has 60 atrack, then the unique 30 xtrack are 3x3 fovs
% so the nadir "xtracks" would be 14,15 which would give 9+9 = 18 samples per atrack, quite a few!!!

%%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%%%         start modification to HHA code
%%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

iFlip = -1;            %% assume you can just stick to HHA orig algorithm
iForwardBackward = +1; %% dont have to worry about first part of granule vs last part of granule

% $$$ center = find(prof.xtrack == 15 | prof.xtrack == 16);  % use xtrack to              
% $$$ center = find(abs(sza)<2.75); % find all near nadir spectr
% $$$ center = find(abs(sza)<1.75); % find all near nadir spectr
center = find(prof.xtrack == 15);  % use xtrack to find nadir
                                   % instead of sza

center = center(1:9:length(center)); %% subset one every 9 which
                                     %% SHOULD be the center, need
                                     %% ti check
dadiff = diff(lat2(center));
junk = find(dadiff > 0);  positive(junk) = +1;
junk = find(dadiff <= 0); positive(junk) = -1;
lat20 = lat2;
meanlat0 = mean(lat2(:));
numAtrack = 180;

if (length(find(positive > 0)) ~= length(dadiff)) & (length(find(positive < 0)) ~= length(dadiff))
  iFlip = +1;
  disp(' <<< polar granule >>> ');
  startpositive = positive(1);
  numAtrack = find(positive ~= startpositive,1);

  centerlat = lat2(center);
  numBtrack = find(abs(centerlat) <= 78);

  junk = find(numBtrack <= numAtrack);
  numAtrack = max(numBtrack(junk));

  if length(numAtrack) == 1
    %%% things were fine, we had enough data before getting to |rlat| == 78
    iForwardBackward = +1;	
    indstop = numAtrack*90;
    [prof] = simple_subset_rtp(prof,1:indstop);
    lon2 = reshape(prof.rlon,90,numAtrack);
    lat2 = reshape(prof.rlat,90,numAtrack);
    reason = uint16(zeros(size(lon2))); 
    sza   = reshape(prof.satzen,90,numAtrack);
  else
    %%% oops no data from beginning of gran to |rlat| == 78, so look at END of granule at subset
    iForwardBackward = -1;	  
    numAtrack = min(numBtrack);
    indstop = numAtrack*90+1;
    [prof] = simple_subset_rtp(prof,indstop:length(prof.rlon));
    lon2 = reshape(prof.rlon,90,180-numAtrack);
    lat2 = reshape(prof.rlat,90,180-numAtrack);
    reason = uint16(zeros(size(lon2))); 
    sza   = reshape(prof.satzen,90,180-numAtrack);
    minAtrack = min(prof.atrack);
  end
  blat2 = lat2;
  
  fprintf(1,'  changed mean lat from %8.6f to %8.6f; numAtrack now %3i \n',meanlat0,mean(blat2(:)),numAtrack)
else
  blat2 = lat2;
end

%%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%%%         end modification to HHA code
%%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

% $$$   vx = find(abs(sza)<1.75); % find all near nadir spectra
vx = find(prof.xtrack == 15 | prof.xtrack == 16);

%%% back to HHA algorithm

%sn = size(vx,1);
sn = length(vx);    
% This is key randomly permute the near nadir ID's.
vxr = vx(randperm(sn));

% Subset these near nadir by cos(lat of gran mean).
if iFlip > 0
  nsave0 = floor(sn*abs(cos(mean(lat20(:))/57.3))+0.5);
end
nsave = floor(sn*abs(cos(mean(blat2(:))/57.3))+0.5);

if iFlip > 0
  fprintf(1,'<lat> = %8.6f : orig nsave = %3i, final nsave = %3i -- will reduce by 1/6 \n',mean(blat2(:)),nsave0,nsave)
  nsave = min(nsave,nsave0);
else
  fprintf(1,'<lat> = %8.6f : nsave = %3i -- will reduce by 1/6 \n',mean(blat2(:)),nsave)
end

if abs(mean(blat2(:))) > 30
  PX = [-6.781163592359652e-06     8.826415250236825e-04    -3.817478053811275e-02     1.534451094844683e+00];
  adj_factor = polyval(PX,abs(mean(blat2(:))));
  fprintf(1,'     *** *** *** adjusting nsave by factor %8.6f \n',adj_factor);
  nsave = ceil(nsave * adj_factor);
end

% This leads to too many random, so pick every 6th one
% Remember vxr is already randomized so this is OK
jump = 6;   %%% this gives about 7000 daily random, while AIRS v6 gives about 21000
jump = 6/3; %%% so this should this give about 7000 x 3 daily random, while AIRS v6 gives about 21000
vc = vxr(1:jump:nsave); 

% Set the reason flag
reason(vc) = bitset(reason(vc),4);
site_id(vc) = 88;

keep_ind = vc;
keep     = vc;

