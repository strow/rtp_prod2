function [head,hatt,prof] = fill_co(head,hatt,prof)
%
% Uses MOPITT XCO data to adjust the std.atmosphere profile.
%      XCO std.atm ~= 2.47x10^18 cm-2 (after klayers)
%
%

addpath /home/chepplew/myLib/matlib

disp('fill_co.m: adding CO')

co = struct;
% The XCO from the std. atmosphere (calculated after klayers)
co.xstd = 2.47E18;      % cm-2

% home of the MOPITT CO monthly mean data
% files run from 200003 to 202103 with some missing
mop.home = '/home/chepplew/data/MOPITT/';
mop.list = dir([mop.home 'MOP03JM-*L3V95.9.3.he5']);

% ref: https://climate.nasa.gov/news/2291/fourteen-years-of-carbon-monoxide-from-mopitt/
%  long-term linear trend 2000:2014 approx -1.57 ppbv/year or: -1.25%/yr
co.trnd_pcpyr = -1.25;

% Sample AIRS granule
%hdf_fn='/asl/airs/l1c_v672/2019/018/AIRS.2019.01.18.001.L1C.AIRS_Rad.v6.7.2.0.G19360072949.hdf';

%[head,hattr,prof,pattr] = airs_l1c_to_rtp(hdf_fn,0);

% allocate memory for gas_5 (CO)
nprofs     = size(prof.plevs,2);
prof.gas_5 = nan(size(prof.plevs));

%
offset = 0;
mtime = tai2dnum(prof.rtime) - offset;

% round to nearest hour in day
rmtime = round(mtime*8)/8;
timestr = datestr(rmtime,'yyyymmddhh');
ystr = timestr(:,1:4);
mstr = timestr(:,5:6);
dstr = timestr(:,7:8);
hstr = timestr(:,9:10);

uyr = unique(str2num(ystr));
umn = unique(str2num(mstr));
udy = unique(str2num(dstr));

% ---------------------------------------------------
% Select MOPITT L3 file. Check in range, load CO data
% ---------------------------------------------------
clear mopdnum
for i=1:length(mop.list)
  junk = strsplit(mop.list(i).name,{'-','.'});
  mopdnum(i) = datenum(junk{2},'yyyymm');
end

if( mean(rmtime(:)) >= mopdnum(1) & mean(rmtime(:)) <= mopdnum(end) ) 
    iimpd = find(mopdnum == datenum(sprintf('%4d%02d',uyr,umn),'yyyymm') );
  if(isempty(iimpd)) 
    uyr = uyr+1;
    iimpd = find(mopdnum == datenum(sprintf('%4d%02d',uyr,umn),'yyyymm') );
  end
elseif(mean(rmtime(:)) < mopdnum(1))
   disp('Earlier than MOPITT data - extrapolating from nearest')
   iimpd = 1;   
elseif(mean(rmtime(:)) > mopdnum(end))
   disp('Later than MOPITT data - extrapolating from nearest')
   iimpd = length(mopdnum);
end

% Got valid year.month to use MOPITT
mop.fn  = [mop.list(iimpd).folder '/' mop.list(iimpd).name];
mop.lat = h5read(mop.fn,'/HDFEOS/GRIDS/MOP03/Data Fields/Latitude');
mop.lon = h5read(mop.fn,'/HDFEOS/GRIDS/MOP03/Data Fields/Longitude');
mop.co  = h5read(mop.fn,'/HDFEOS/GRIDS/MOP03/Data Fields/RetrievedCOTotalColumnDay');
% Deal with missing data (-999)
inan = find(mop.co < 0);
mop.co(inan) = NaN;

% =================================================================
% Interpolate CO field to obs locations, account for missing values
% =================================================================
[X,Y] = ndgrid(mop.lon, mop.lat);
iX = flipud(X); iY = flipud(Y);

% simplemap(iY, iX, mop.co')  % iY=latitude [180], iX=longitude [360] mop.co [180x360]
% 360 lon x 180 lat. Column CO.
clear F
  %%F.co2(i).ig = griddedInterpolant(iX,iY,flipud(single(sd.co2(:,:,i))),'linear');
  %%F.co2(i).ig = griddedInterpolant(Y',X',flipud(squeeze(sd.co2(:,:,i))),'linear');
  F.co.ig = griddedInterpolant(X,Y,mop.co','linear');
  %F.co2(i).ig = griddedInterpolant(X,Y,(squeeze(sd.co2(:,:,i))),'nearest');

% Assume rtp lat/lon are +-180??  Need to be 0-360 for interpolation
% loop over rlat,rlon
clear co.intrp;
for isp = 1:length(prof.rlat)
   rlat = prof.rlat(isp);
   rlon = prof.rlon(isp);
   %rlat(rlat<0) = rlat(rlat<0) + 90;
   %rlon(rlon<0) = rlon(rlon<0) + 360;
   co.intrp(isp)  = F.co.ig(rlon, rlat);
end
% Need to fill missing data:
inan=find(isnan(co.intrp));
if(length(inan) >= 1)
  co.intrp = fillmissing(co.intrp,'nearest');
end

% ====================================================================
% Load up most appropriate standard atmosphere to tack on upper levels
% ====================================================================
% st.atm CO(z) is ppmv at level Z. XCO equiv: 2.474e+18 cm-2.
opts = struct;
opts.latitude = nanmean(prof.rlat);
opts.year     = uyr;
opts.month    = umn;
atm = load_standard_atmos(opts);

% ======================================================
% Account for CO change beyond period of CO measurements
% ======================================================
% Extrapolate if needed CO data to current time:
if(mean(rmtime(:)) < mopdnum(1) | mean(rmtime(:)) > mopdnum(end) )
  delta_time = mopdnum(iimpd) - mean(rmtime(:));
  co.scale   = 0.01*delta_time*co.trnd_pcpyr/365;
  co.xtrp    = co.intrp.*(1 + co.scale);
else
  co.xtrp    = co.intrp;
end

% %xvals = ch4.annyrs - ch4.annyrs(1);
% %xq    = datenum([uyr(1) umn(1) 1]) - ch4.annyrs(1);
% %ch4.upd = interp1(xvals, ch4.annmean, xq,'linear','extrap');
% %dfrac = 1.0 + (res_co - std_xco)./std_xco;

% Scale the std ATM CO(z) to the surface abundance - apprx column amt.
co.xscale = co.xtrp./co.xstd;
co.newprof = co.xscale.*atm.CO;
xplevs     = repmat(atm.PRE,1,length(co.newprof));

% check size of res2_co [50 x nprofs]
% <TBD>

% reverse ordering of pressure (TOA to SFC)
xplevs     = xplevs(end:-1:1,:);
co.newprof = co.newprof(end:-1:1,:);

%{
% add to previous profile plot
  plot(nanmean(res2,2), nanmean(prs2,2),'g.-')
%}

% Interpolate to the 60-levels of the ECMWF fields
clear gas_5;
for i = 1:nprofs
  gas_5(:,i) = interp1(xplevs(:,i), co.newprof(:,i), prof.plevs(:,i),'linear','extrap');
end

% update head and prof
head.ngas  = head.ngas + 1;
head.glist = [head.glist; 5];
head.gunit = [head.gunit; 10];   % ppmv dry air

prof.gas_5 = gas_5;


%{
% Send through klayers

%}

