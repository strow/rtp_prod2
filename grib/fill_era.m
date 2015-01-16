% fill_ecmwf.m
% 
% L. Strow, 12 Jan 2015
%
% Start with fill_ecmwf.m and modify for ERA

function [prof, head] = fill_era(prof, head);

addpath /asl/matlib/aslutil

% Location of grib files
fhdr = '/asl/data/era/';

ename = '';  % This should be placed outside a rtp file loop
%mtime = iasi2mattime(prof.rtime);
mtime = tai2mattime(prof.rtime);
% Need for AIRS mtime = tai2mattime(prof.rtime);

% Get a cell array of ecmwf grib files for each time
% Round to get 4 forecast hours per day
rmtime = round(mtime*4)/4;
timestr = datestr(rmtime,'yyyymmddhh');
ystr = timestr(:,1:4);
mstr = timestr(:,5:6);
dstr = timestr(:,7:8);
hstr = timestr(:,9:10);
yearindex = str2num(ystr);
dayindex = str2num(dstr);
hourindex = str2num(hstr);

enames = [ystr mstr dstr];
enames = cellstr(enames);
[u_enames, ia, ic] = unique(enames);
n = length(u_enames); % Generally 2 names for 1 day's worth of data

for i=1:n
   fn = fullfile(fhdr,u_enames{i}(1:4),u_enames{i}(5:6),u_enames{i});
   fn_lev = [fn '_lev.nc'];
   fn_sfc = [fn '_sfc.nc'];
% Do the netcdf files exist?
   if exist(fn_sfc,'file') == 0 || exist(fn_lev,'file') == 0 
      disp(['Netcdf grib files missing for root: ' fn])
      break % Go to next partition
   end
% If the filename has changed, re-load F   
   if ~strcmp(ename,fn) 
      clear F  % Probably not needed
      disp('New file')
      F(1) = grib_interpolate_era(fn_sfc,fn_lev,1);
      F(2) = grib_interpolate_era(fn_sfc,fn_lev,2);
      F(3) = grib_interpolate_era(fn_sfc,fn_lev,3);
      F(4) = grib_interpolate_era(fn_sfc,fn_lev,4);
      ename = fn;
   end   
% Fill rtp fields
   m = find( ic == i );  % indices of first era file
   fhi = 0;
   u_hour = unique(hourindex);
   nn = length(u_hour);
   for jj=1:nn
       fhi = 1;
       l = find( hourindex == u_hour(jj));
       k = intersect(l,m);       
   
% Assume rtp lat/lon are +-180??  Need to be 0-360 for grib interpolation
       rlat = prof.rlat(k);
       rlon = prof.rlon(k);
       rlon(rlon<0) = rlon(rlon<0) + 360;

       prof.spres(k)   = F(fhi).sp.ig(rlat,rlon);
       prof.stemp(k)   = F(fhi).skt.ig(rlat,rlon);
       wind_v          = F(fhi).v10.ig(rlat,rlon);
       wind_u          = F(fhi).u10.ig(rlat,rlon);
       prof.wspeed(k)  = sqrt(wind_u.^2 + wind_v).^2;
       prof.wsource(k) = mod(atan2(single(wind_u), single(wind_v)) * 180/pi,360);
       prof.cfrac(k)   = F(fhi).tcc.ig(rlat,rlon);
       ci_udef = 1;
       prof.udef(ci_udef,k) = F(fhi).ci.ig(rlat,rlon);
% Estimate model grid centers used
       gdlat = abs(nanmean(diff(F(fhi).h_latitude)));  % lat spacing
       gdlon = abs(nanmean(diff(F(fhi).h_longitude))); % lon spacing
       prof.plat(k) = floor(rlat/gdlat)*gdlat + gdlat/2;
       prof.plon(k) = floor(rlon/gdlon)*gdlon + gdlon/2;

% F(fhi).tcwv.ig  % Total column water?  Use this instead of ours?
% F(fhi).msl.ig   % Not in rtp for now
% Hybrid parameters
% levid = 1 is top of atmosphere
% b are the sortedd level IDs   
%       prof.nlevs = ones(1,length(k))*length(F(fhi).levid);
       [b,j]=sort(F(fhi).levid);
       for l=1:length(F(fhi).levid)
          prof.ptemp(l,k) = F(fhi).t(j(l)).ig(rlat,rlon);
          prof.gas_1(l,k) = F(fhi).q(j(l)).ig(rlat,rlon);
          prof.gas_3(l,k) = F(fhi).o3(j(l)).ig(rlat,rlon);
          prof.cc(l,k)    = F(fhi).cc(j(l)).ig(rlat,rlon);
          prof.clwc(l,k)  = F(fhi).clwc(j(l)).ig(rlat,rlon);
          prof.ciwc(l,k)  = F(fhi).ciwc(j(l)).ig(rlat,rlon);
       end
% Only want pressure levels in grib file, in order
       xtemp = p60_ecmwf(prof.spres(k));  % all 137 pressure levels
       prof.plevs(:,k) = xtemp(b,:);  % subset to ones in grib file
       prof.nlevs(k) = length(F(fhi).levid);
   end
   fhi = fhi + 1;
end

% Header info
head.ptype = 0;
head.ngas = 2;
head.glist = [1; 3];
head.gunit = [21; 21];
head.pmin = min( prof.plevs(1,:) );
head.pmax = max( prof.plevs(end,:) );
% Setting attributes needs work...
% pattr = set_attr(pattr,'profiles','ECMWF','profiles');

% I think this is needed to avoid negatives in SARTA?
min_H2O_gg = 3.1E-7;  % 0.5 pppm
min_O3_gg = 1.6E-8;   % 0.01 ppm
% Find/replace bad mixing ratios
if isfield(prof,'gas_1')
  ibad = find(prof.gas_1 <= 0);
  nbad = length(ibad);
  if (nbad > 0)
    prof.gas_1(ibad) = min_H2O_gg;
%    say(['Replaced ' int2str(nbad) ' negative/zero H2O mixing ratios'])
  end
end
%
if isfield(prof,'gas_3')
  ibad = find(prof.gas_3 <= 0);
  nbad = length(ibad);
  if (nbad > 0)
    prof.gas_3(ibad) = min_O3_gg;
%    say(['Replaced ' int2str(nbad) ' negative/zero O3 mixing ratios'])
  end
end
%  fix any cloud frac
if isfield(prof,'cfrac')
  ibad = find(prof.cfrac > 1);
  nbad = length(ibad);
  if (nbad > 0)
    prof.cfrac(ibad) = 1;
%    say(['Replaced ' int2str(nbad) ' CFRAC > 1 fields'])
  end
end
