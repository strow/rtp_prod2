function [prof, pattr] = rtp_add_emis_single(prof, pattr);
% rtp_add_emis.m
% Usage: prof = rtp_add_emis(prof);
% 
% Insert Dan Zhou's surface emissivity climatology for surface and
% standard sea surface emissivity for water scenes.
%
% This routine nominally assume rtp prof structures for emissitvity 
% don't exist on input.
%
% Since Dan Zhou's emissivity is based on IASI channels, here we pick a
% subset of 100 channels max to return.  This can be made more arbitrary
% in the future. Note that at present, SARTA is set for a maximum of 100
% emissivity points. (Need Zhou reference.)
% 
% For water scenes, just use the 19 points we have been using. (Need
% reference.)
% 
% L. Strow, Feb. 4, 2015

% Ad-hoc decisions below on channel selection.  I have picked a higher
% density of points in the 10 um window silicate bands.  This could be
% hardcoded into an array we load?  Or, make it arbitrary and use 
% Howard's seq_match to find the closest IASI channels to the requested
% emissivity frequencies.  The efreq are then matched again to IASI 
% frequency indices in emis_danz to retain they ability to call emis_danz
% with arbitrary frequencies.
%
% Silicate band spacing of 34 channels
k1 = 1478:34:2610;
% Rest of spectrum uses 112 channel spacing so get 100 total
k2 = [1:112:1443 2633:112:8461];
% Union of above, sorted
k  = [k1 k2];
efreqi = sort(k);
clear k k1 k2
% rtp need frequencies for these channels
load /asl/rta/iremis/danz/iasi_f
efreq = fiasi(efreqi);

% Only ask emis_danz for land emissivities, any fraction
kland     = find( prof.landfrac > 0 );
emis_land = emis_danz_single(prof.rlat(kland),prof.rlon(kland),prof.rtime(kland),efreq);
% Get sea emissivities, only for pure water scene
kwater    = find( prof.landfrac <= 0);
[sea_nemis, sea_efreq, sea_emis] = emis_sea(prof.satzen(kwater), prof.wspeed(kwater));

% Declare emissivity arrays
nobs       = length(prof.rlat);
prof.nemis = single(ones(1,nobs));
% 100 below is SARTA max
prof.efreq = single(ones(100,nobs));
prof.emis  = NaN*single(ones(100,nobs));

% Fill rtp with land emissivity info
[nemis ~] = size(emis_land);
prof.nemis(kland) = prof.nemis(kland)*nemis;
prof.emis(1:nemis,kland) = emis_land;
for i = 1:length(kland)
   prof.efreq(1:nemis,kland(i)) = efreq';
end

% Fill rtp with water emissivity info
prof.nemis(kwater) = prof.nemis(kwater)*sea_nemis;
prof.emis(1:sea_nemis,kwater) = sea_emis;
for ifov = kwater
  prof.efreq(1:sea_nemis,ifov) = single(sea_efreq)';
end

% Now do obs with fractional land/sea
% If any fraction land, started with land emissivity (above)
% Interpolate water emissivity onto land efreq grid and then 
% partition emissivity by land/water fraction
lmix = (prof.landfrac > 0 & prof.landfrac < 1 );
for ifov = find(lmix)
  lf = prof.landfrac(ifov);
  of = 1-lf;
  sea_emis_on_landgrid = interp1(efreq,prof.emis(:,ifov),efreq,'linear');
  prof.emis(:, ifov) = single(of*sea_emis_on_landgrid + lf*prof.emis(:,ifov));
end

% Compute Lambertian Reflectivity
prof.nrho = single(prof.nemis);
prof.rho  = single((1.0 - prof.emis)./pi);

% set an attribute string to let the rtp know what we have done
pattr = set_attr(pattr,'emis','Land: emis_danz.m, Water:emis_sea.m');


