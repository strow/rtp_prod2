function [reason ikeep] = random_eq_area(prof)
%
% NAME:
%
% SYNOPSIS:
%
% USEAGE:
%
% INPUTS:
%
% OUTPUTS:
%
% DEPENDENCIES: None.
%       
% NOTES:
%

tim1  = prof.rtime(1);
rand('seed',tim1(1,1));

satza = prof.satzen;

[mm nn]  = size(prof.rlat);
reason   = uint16(zeros(mm,nn));

fov1     = find(prof.ifov == 1);
center0  = find(prof.xtrack == 15 | prof.xtrack == 16);     % full set IFOVs to randomize
center1  = find(prof.xtrack == 15 & prof.ifov == 2);        % use for finding polar granule
%center = center(1:9:length(center));

% ------------------------------------------------------------------------
%{
iFlip = -1;            %% assume you can just stick to HHA orig algorithm
iForwardBackward = +1; %% dont have to worry about first part of granule vs last part of granule

clear positive;
dadiff = diff(prof.rlat(center1));
junk   = find(dadiff > 0);  positive(junk) = +1;
junk   = find(dadiff <= 0); positive(junk) = -1;
lat20  = prof.rlat;
mnlat0 = mean(prof.rlat(:));
mnlat1 = mean(prof.rlat(center1));
numAtrack = 180;

if (length(find(positive > 0)) ~= length(dadiff)) & (length(find(positive < 0)) ~= length(dadiff))
  iFlip = +1;
  disp(' <<< polar granule >>> ');
  startpositive = positive(1);
  numAtrack = find(positive ~= startpositive,1);

  centerlat = prof.rlat(center1);
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
    [prof] = simple_subset_rtp(pd,indstop:length(pd.rlon));
    lon2 = reshape(prof.rlon,90,180-numAtrack);
    lat2 = reshape(prof.rlat,90,180-numAtrack);
    reason = uint16(zeros(size(lon2))); 
    sza   = reshape(prof.satzen,90,180-numAtrack);
    minAtrack = min(prof.atrack);
  end
  vx = find(abs(prof.satzen) < 1.75); % find all near nadir spectra

  blat2 = lat2;
  
  fprintf(1,'  changed mean lat from %8.6f to %8.6f; numAtrack now %3i \n',meanlat0,mean(blat2(:)),numAtrack)
else
  blat2 = lat2;
end

%}
% ---------------------------------------------------------------------------------

vx    = find(abs(prof.satzen) < 3.5);      % center FORs, same as center0 (FOR 15 + 16)
sn    = length(vx);

vxr   = vx(randperm(sn));

% find the mean latitude of this granule based on center FORs:
mnlat   = mean(prof.rlat(vx));

nsave = floor(sn*abs(cos(mnlat/57.3)) + 0.5);

if abs(mean(prof.rlat(vx))) > 30
  PX = [-6.781163592359652e-06 8.826415250236825e-04 -3.817478053811275e-02 1.534451094844683e+00];
  adj_factor = polyval(PX,abs(mean(prof.rlat(vx))));
  %fprintf(1,'     *** *** *** adjusting nsave by factor %8.6f \n',adj_factor);
  nsave = ceil(nsave * adj_factor);
end

nsave1 = nsave;
% apply 'notch filter' to samples from 78 to 82 latitude:
 xx     = [-4:.2:4];
 norm   = normpdf(xx,0,1);         % [1x41] normal - set to peak at 90-deg
 xbands = [76:0.5:96]; nxbands = length(xbands);
 for j=1:15                        % 76 to 83 latitude is adequate
   clear innotch;
   innotch =  find( abs(prof.rlat(vx)) > xbands(j) & abs(prof.rlat(vx)) <= xbands(j+1) );
   if(innotch)
     notch_fact = (max(norm) - norm(j+5))/max(norm);       % +5 to get steeper slope
     nsave      = ceil(nsave1 * notch_fact);
   end
 end
 
% reduce further:
vc = vxr(1:2:nsave);

% set the reason flag
reason(vc) = bitset(reason(vc),4);               % bit 4=1 :- dec value 8.

% set index of obs to keep
ikeep = vc;

%{
% optional plotting
  figure(1);clf;plot(pd.rlat(vc),'k.');grid;     % rlat(vx) or vc

%}
