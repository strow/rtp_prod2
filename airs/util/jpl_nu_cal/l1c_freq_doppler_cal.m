function [radiances_nucal_scan] = l1c_freq_doppler_cal(prof);
%
% Returns L1c radiances (90x135) corrected for frequency shift due to the 
% instrument drifts and the Doppler effect.  The returned frequencies are
% sampled to the official L1c frequency scale.
% establish local directory structure
currentFilePath = mfilename('fullpath');
[cfpath, cfname, cfext] = fileparts(currentFilePath);

%======== Load in data that will be presistent ==============
% The official l1c channels, we interpolate to this scale
persistent fl1c
if isempty(fl1c)
   load(fullfile(cfpath, '../static/fl1c.mat'));
end

% Indices for swtiching from l1c to l1b and back
persistent   l1b_ind_in_l1c  l1c_ind_for_l1b
if isempty(l1b_ind_in_l1c ) | isempty(l1c_ind_for_l1b)
   load(fullfile(cfpath, '../static/indices_of_l1b_in_l1c.mat'));
end
%======================== Read L1c File Vars Needed =====================

%% No error trapping yet for partial granules, not sure if this is an issue
%% If need to trap, start by getting "state" variable below, and then only
%% read variables from 1:n0, etc etc.  Maybe needed for "bad" granules too?
%% L Strow can implement if you give me some bad granules for testing
% junk = hdfread(fn, 'state');
% state = reshape( double(junk'), 1,nobs);
% i0=find( state == 0);  % Indices of "good" FOVs
% n0=length(i0);

% Granule length
nobs = 90*135;
nxtrack = 90;
natrack = 135;
nobs = nxtrack*natrack;
nchan = 2645;

[xtr, atr] = meshgrid(1:nxtrack,1:natrack);
lxtr = reshape(xtr',nobs,1);
latr = reshape(atr',nobs,1);

% Per scan line variables
% scan_node_type   prof.iudef(4,:)
scan_node_type = prof.iudef(4,:);
% sat_lat   prof.sat_lat
sat_lat = prof.satlat;

% 90 x 135 variables
% latitude  prof.rlat
Latitude = prof.rlat;
% Longitde  prof.rlon
Longitude = prof.rlon;
% Time      prof.rtime
Time = prof.rtime;
mtime = tai2dtime(Time);
% satzen    prof.satzen
satzen = prof.satzen;
% satazi    prof.satazi
satazi = prof.satazi;
% radiances prof.robs1
radiances = prof.robs1;

%============================== Form Orbit Phase ==========================
opi = NaN(nobs,1);
% Descending from equator to S. Pole
kd = (scan_node_type == 68 & Latitude <= 0);
opi(kd) = abs(Latitude(kd)/2);
% Descending from N. Pole to equator
kd = (scan_node_type == 68 & Latitude >= 0);
opi(kd) = 135 + 90/2 -Latitude(kd)/2;

% Ascending from S. Pole to equator
ka = (scan_node_type == 65 & Latitude < 0);
opi(ka) = 45 + 90/2 + Latitude(ka)/2;
% Ascending from equator to N. Pole
ka = (scan_node_type == 65 & Latitude > 0);
opi(ka) = 90 + Latitude(ka)/2;

%=========================== Get Obs Frequency ==========================
% Get indices into yoff matrix which handles 1:180 for opi
% No interpolation of orbit phase, just use closest of 180 phases in table
[c,ia,ib] = unique(round(opi));
% Will not worry about ab changing during a granule 
ab_time = get_ab_state(nanmean(mtime));

% Get freq, the actual (computed) frequencies for the observation at mtime
for i=1:length(c)
   yoff = get_yoff(nanmean(mtime));
   % Only do gmodel on unique orbit phases, fill these back to all scenes   
   [f_lm,freq(i,:),m_lm,module] = gmodel(155.1325,yoff(:,round(opi(ia(i)))),ab_time);
end
% Fill in freqs for all scenes
tmp_freqall = freq(ib,:);

% % Only shift true l1b channels in l1c
% freqall = freqall(:,l1b_ind_in_l1c);

%=========================== Get Doppler Shift ==========================
dnu_ppm = doppler_jpl(scan_node_type,lxtr,satzen,satazi,sat_lat);
dnu     = dnu_ppm*1E-6.*tmp_freqall;
tmp_freqall = tmp_freqall + dnu;

[nx ny ] = size(radiances);

% Convert tmp_freqall to L1c channels, fill with standard L1c freqs first to fill fake channels
freqall = zeros(nx,ny);
freqall = freqall + fl1c';
% Now fill in frequencies for l1b channels from grating model
freqall(:,l1c_ind_for_l1b) = tmp_freqall(:,l1b_ind_in_l1c);

l1b_btobs = NaN(nx,ny);   % Gives big speed up for loop below, 2.7 seconds was 66 seconds
for i = 1:nx
  l1b_btobs(i,:) = rad2bt(freqall(i,:),radiances(i,:));
end

tmp_btobs = NaN(nx,ny);
% This is the slowest part of this code: 23.6 seconds
for i=1:nx
   tmp_btobs(i,:) = jpl_shift(l1b_btobs(i,:),freqall(i,:),fl1c);
end

% Pre-allocation gives big speed up
radiances_nucal = NaN(nx,ny);   
% Matlab will preserve negative radiances, says testing, do NOT ask for real part of tmp_btobs
for i = 1:nx
  radiances_nucal(i,:) = bt2rad(fl1c,tmp_btobs(i,:));
end

radiances_nucal_scan = reshape(radiances_nucal,90,135,2645);
radiances_nucal_scan = permute(radiances_nucal_scan,[3 1 2]);

%========================= Testing code for Orbit Phase ==========================
% d = 3037;  % Roughly 1/4 of full granule
% 
% i1 = 1:d;
% i2 = d+1:2*d;
% i3 = 2*d+1:3*d;
% i4 = 3*d+1:4*d;
% 
% lat = NaN(12150,1);
% lat(i1) = linspace(   0,-90,length(i1));
% lat(i2) = linspace( -90,0,  length(i1));
% lat(i3) = linspace(   0,90, length(i1));
% lat(i4) = linspace(  90,0,  length(i1));
% 
% scan_node_type = NaN(12150,1);
% scan_node_type(i1) = 1;
% scan_node_type(i2) = 0;
% scan_node_type(i3) = 0;
% scan_node_type(i4) = 1;
