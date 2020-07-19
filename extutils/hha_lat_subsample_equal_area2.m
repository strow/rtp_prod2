function [keep,keep_ind] = hha_lat_subsample_equal_area2(head0,prof0)

% based on hha_rand.m

% lat_subsample_equal_area(lat);
%
% Inputs:  head,prof : structure containing rlat,tlon,atrack,xtrack etc
%          ASSUMES prof has allfov 12150 (90x135) data
% Output:  keep     : indices 2D matrix of input vector (xtrack,atrack) to keep
%          keep_ind : changing those 2d indices into one that indexes (1x12150)
%
addpath /asl/packages/ccast/motmsc/time
addpath /asl/matlib/rtptools/

head = head0;
prof = prof0;
iaDoNotUse = zeros(1,12150);
iaBad = [];
iOops = -1;

if length(prof.atrack) < 12150
  iOops = +1;
  fprintf(1,'expecting 12150 fovs, only have %5i .. temporary fix \n',length(prof.atrack))
  [prof,iaBad] = fix_numfovs_12150(prof);
  iaDoNotUse(iaBad) = +1;
end

% Pick a time for initializing random number generator
tai = prof.rtime(1);

% Nice changing random seed
rand('seed',tai(1,1));  % random selection initialization.

% Pick a nominal latitude, longitude
lon2 = reshape(prof.rlon,90,135);
lat2 = reshape(prof.rlat,90,135);

% Initialize reason since same FOV can be picked for different
% reasons, it has to be updated from a starting point
reason = uint16(zeros(size(lon2))); 
sza   = reshape(prof.satzen,90,135);

% Each granule has 135*6=810 near nadir spectra

% Now the selection
% why this? Just use xtrack...
vx = find(abs(sza)<1.5); % find all near nadir spectra
vx = find(abs(sza)<3.5); % find all near nadir spectra

%%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%%%         start modification to HHA code
%%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

iFlip = -1;            %% assume you can just stick to HHA orig algorithm
iForwardBackward = +1; %% dont have to worry about first part of granule vs last part of granule

dadiff = diff(lat2(46,:));
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

  centerlat = lat2(46,:);
  numBtrack = find(abs(centerlat) <= 78);

  junk = find(numBtrack <= numAtrack);
  numAtrack = max(numBtrack(junk));

  if length(numAtrack) == 1
    %%% things were fine, we had enough data before getting to |rlat| == 78
    iForwardBackward = +1;	
    indstop = numAtrack*90;
    [head,prof] = subset_rtp(head,prof,[],[],1:indstop);
    lon2 = reshape(prof.rlon,90,numAtrack);
    lat2 = reshape(prof.rlat,90,numAtrack);
    reason = uint16(zeros(size(lon2))); 
    sza   = reshape(prof.satzen,90,numAtrack);
  else
    %%% oops no data from beginning of gran to |rlat| == 78, so look at END of granule at subset
    iForwardBackward = -1;	  
    numAtrack = min(numBtrack);
    indstop = numAtrack*90+1;
    [head,prof] = subset_rtp(head,prof,[],[],indstop:length(prof.rlon));
    lon2 = reshape(prof.rlon,90,135-numAtrack);
    lat2 = reshape(prof.rlat,90,135-numAtrack);
    reason = uint16(zeros(size(lon2))); 
    sza   = reshape(prof.satzen,90,135-numAtrack);
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

[i,j]=ind2sub([90 numAtrack],vc);

keep = [i,j];  %% keep(:,1) = xtrack     keep(:,2) = atrack
if length(iaBad) > 0
  keep_junk_index = (keep(:,2)-1)*90 + keep(:,1);
  if length(intersect(keep_junk_index,iaBad)) > 0
    %% need to trim this pie
    disp('  >>> oh oh some of the BAD fovs have crept into chosen fovs; removing <<< ');    
    [Y,iA] = setdiff(keep_junk_index,iaBad);
    keep = keep(iA,:);
  end
%else
%  disp('12150 fovs no problemo')
end
clear keep_junk_index

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

%% now send out the indexes into (1:12150) that we need (ie into (atrack-1)*90 + xtrack)

prof0_index = (prof0.atrack-1)*90 + prof0.xtrack;
prof_index  = (prof.atrack-1)*90 + prof.xtrack;

if iForwardBackward == -1
  %% oops more relevant data was in last part of granule, after going over the pole
  keep(:,2) = keep(:,2) + (minAtrack-1);
end
    
keep_junk_index = (keep(:,2)-1)*90 + keep(:,1);
[Y,I] = sort(keep_junk_index);
for ii = 1 : length(I)
  keepnew(ii,1) = keep(I(ii),1);
  keepnew(ii,2) = keep(I(ii),2);
end

if length(keep_junk_index) > 0
  keepnew_junk_index = (keepnew(:,2)-1)*90 + keepnew(:,1);
  [junk,iA,keep_ind] = intersect(keepnew_junk_index,prof_index);
  if iForwardBackward == -1
    keep_ind = keep_ind + (minAtrack-1)*90;
  end	
else
  keep_ind = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%
iaFinalCheck1 = find(keep_ind > length(prof0.atrack));
if length(iaFinalCheck1) > 0
  disp('  >>> oh oh still have some BAD fovs in the final check1, removing <<< ');    
  iA = find(keep_ind <= length(prof0.atrack));
  keep = keep(iA,:);
  keep_ind = keep_ind(iA);
end

iaFinalCheck2 = find(prof0.xtrack(keep_ind) < 43 | prof0.xtrack(keep_ind) > 48 | isnan(prof0.xtrack(keep_ind)));
if length(iaFinalCheck2) > 0
  disp('  >>> oh oh still have some BAD fovs in the final check2, removing <<< ');    
  [Y,iA] = setdiff(1:length(keep_ind),iaFinalCheck2);
  keep = keep(iA,:);
  keep_ind = keep_ind(iA);
end
%%%%%%%%%%%%%%%%%%%%%%%%%

dodo = find(prof0.xtrack == 45 | prof0.xtrack == 46);
figure(1); clf;
  plot(1:length(prof0.rlat),prof0.rlat,'b.',dodo,prof0.rlat(dodo),'kx'); hold on
  plot(keep_ind,prof0.rlat(keep_ind),'ro'); hold off
  ylabel('rlat'); xlabel('fov index')
  title('red dots are sampled indices')
pause(0.1);
	
%[double(prof.xtrack(keep_ind)') - keepnew(:,1)]'
%[double(prof.atrack(keep_ind)') - keepnew(:,2)]'
