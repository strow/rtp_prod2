function [keep,keep_ind] = hha_lat_subsample_equal_area1(prof)

% based on hha_rand.m, tries to map lats 70:70:80 tp 70:90:100 before finding mean

% lat_subsample_equal_area(lat);
%
% Inputs:  prof : structure containing rlat,tlon,atrack,xtrack etc
% Output:  keep : indices of input vector (xtrack,atrack) to keep 
%
addpath /asl/packages/ccast/motmsc/time

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
% Why he does this I don't know.  Just use xtrack...
vx = find(abs(sza)<1.5); % find all near nadir spectra
vx = find(abs(sza)<3.5); % find all near nadir spectra

dadiff = diff(lat2(46,:));
junk = find(dadiff > 0);  positive(junk) = +1;
junk = find(dadiff <= 0); positive(junk) = -1;

iFlip = -1;
if (length(find(positive > 0)) ~= length(dadiff)) & (length(find(positive < 0)) ~= length(dadiff))
  iFlip = +1;
  disp('iFlip');
  startpositive = positive(1);
  thestart = find(positive ~= startpositive,1);
  blat2 = lat2;
  blat2(:,thestart:135) = 90 + (90-abs(blat2(:,thestart:135)));
  if blat2(1,1) < 0
    blat2(:,thestart:135) = -blat2(:,thestart:135);
  end
  fprintf(1,'  changed mean lat from %8.6f to %8.6f \n',mean(lat2(:)),mean(blat2(:)))
else
  blat2 = lat2;
end

figure(1); clf; plot(lat2(46,:)); title(num2str(mean(lat2(:)))); %disp('ret to continue'); pause
figure(2); clf; plot(blat2(46,:)); title(num2str(mean(blat2(:)))); %disp('ret to continue'); pause
pause(0.1);

sn = size(vx,1);    
% This is key randomly permute the near nadir ID's.
vxr = vx(randperm(sn));
% Subset these near nadir by cos(lat of gran mean).
nsave = floor(sn*abs(cos(mean(blat2(:))/57.3))+0.5)

% This leads to too many random, so pick every 6th one
% Remember vxr is already randomized so this is OK
vc = vxr(1:6:nsave); 

% Set the reason flag
reason(vc) = bitset(reason(vc),4);
site_id(vc) = 88;

% Done, now see what we have
figure(3); clf

imagesc(sza'); colorbar; title('colorbar = sza')
hold on;
line([45.5 45.5],[0 135],'color','k','linewidth',2);
line([43 43],[0 135],'color','k');
line([48 48],[0 135],'color','k');
[i,j]=ind2sub([90 135],vc);
plot(i,j,'ro')

keep = [i,j];  %% keep(:,1) = xtrack     keep(:,2) = atrack

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
prof_index      = (prof.atrack-1)*90 + prof.xtrack;

keep_junk_index = (keep(:,2)-1)*90 + keep(:,1);
[Y,I] = sort(keep_junk_index);
for ii = 1 : length(I)
  keepnew(ii,1) = keep(I(ii),1);
  keepnew(ii,2) = keep(I(ii),2);
end

if length(keep_junk_index) > 0
  keepnew_junk_index = (keepnew(:,2)-1)*90 + keepnew(:,1);
  [junk,iA,keep_ind] = intersect(keepnew_junk_index,prof_index);
else
  keep_ind = [];
end

%[double(prof.xtrack(keep_ind)') - keepnew(:,1)]'
%[double(prof.atrack(keep_ind)') - keepnew(:,2)]'
