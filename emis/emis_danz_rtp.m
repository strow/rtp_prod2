%function [emis] = emis_danz_rtp(prof);
function [emis] = emis_danz_rtp(lat,lon,rtime,efreq);
% function [prof] = emis_danz_rtp(prof);
%
% REQUIRES:
%     ~/Git/rtp_prod2;  % seq_match
%
% Returning emis instead of prof for now until get straight
% on code for hinge points

% danz interpolant is big, keep it around
persistent danz
if isempty(danz)
   load Data/danz_interpolant.mat
end

% SVD basis vectors and mean 
load Data/u_vector_global

% Pre-allocate u coefficients, nobs can be very large
[~, nobs] = size(lat);
newc = zeros(10,nobs);

% Now figure out numerical months
mtime = datetime(1993,1,1,0,0,rtime);
mon = single(day(mtime,'dayofyear')/365); % single to go with prof.rlat

% Find interpolated expansion coefficients (linear is default)
for i=1:10
   newc(i,:) = danz(i).emis(lon,lat,mon);
end

% Expand with basis vectors u
% First, find id's of IASI channels we will use
% Assume all the same for now
load_fiasi
[ichan, j] = seq_match(fiasi,efreq(:,1));
emis = u(ichan,:)*newc;

% Add in constant emissivity (from u_vector_global)
for i=1:nobs
   emis(:,i) = emis(:,i) + em(ichan);
end

% Frequencies for emissivities often used in rtp, max in SARTA == 100
% Geez, why so high at the end??  2760 cm-1 is max of all three (iasi)
% efreq_std = [769.23 800.00  833.33  869.57  909.09  952.38 ...
%              1000.00 1041.67 1086.96 1136.36 1190.48 1250.00 ... 
%              2400.00 2439.02 2500.00 2564.10 2631.58 2702.70 2760.00 ];
% 
% [i, j] = seq_match(fiasi,efreq_std);
% 




