function [keep,keep_ind] = hha_lat_subsample_equal_area0(prof)

% based on hha_rand.m

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

sn = size(vx,1);    
% This is key randomly permute the near nadir ID's.
vxr = vx(randperm(sn));
% Subset these near nadir by cos(lat of gran mean).
nsave = floor(sn*abs(cos(mean(lat2(:))/57.3))+0.5);
fprintf(1,' mean lat = %8.6f  nsave = %4i \n',mean(lat2(:)),nsave);

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
