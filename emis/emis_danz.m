function [emis] = emis_danz(lat,lon,rtime,efreq);
% Usage: [emis] = emis_danz_rtp(lat,lon,rtime,efreq);
%
% Returns Dan Zhou's land emissivity climatology
% Dan provides a monthly climatology, here we do both
% temporal and spatial linear interpolation.

% For seq_match to get closest IASI channels to efreq
% Put in standard location soon
addpath ../../util

% danz interpolant is big, keep it around
persistent danz
if isempty(danz)
   load /asl/data/iremis/danz/danz_interpolant.mat
end

% SVD basis vectors and mean 
load /asl/data/iremis/danz/u_vector_global

% Pre-allocate u coefficients, nobs can be very large
[~, nobs] = size(lat);
newc = zeros(10,nobs);

% Now figure out numerical months
mtime = datetime(1993,1,1,0,0,rtime);
mon = day(mtime,'dayofyear')/365;

% Find interpolated expansion coefficients (linear is default)
for i=1:10
   newc(i,:) = danz(i).emis(lon,lat,mon);
end

% Expand with basis vectors u
% First, find id's of IASI channels we will use; hard-code later?
load ../../iasi/iasi_f  % Needs to be put in standard location soon
[ichan, ~] = seq_match(fiasi,efreq);
emis = u(ichan,:)*newc;

% Add in constant emissivity (from u_vector_global)
for i=1:nobs
   emis(:,i) = emis(:,i) + em(ichan);
end
