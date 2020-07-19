function F = grib_interpolate_merra(fn_s,fn_h,hindex);
% 
% Inputs: fn_s, fn_h, hindex
%         Netcdf files containing grib1 and grib2 
%         data respectively.  This code assumes the grib1 data
%         is surface data, and the grib2 data is hybrid ecmwf data.
%         hindex is the hour index (4 total) in the era file

% Output: F, a structure with housekeeping data (lat, lon of grid) and
%         interpolants for interpolating to arbitrary lat/lon positions.
%
% Presently the interpolant is set to be linear, you can also 
% select nearest-neighbor, cubic, etc.  I may make this an option
% in the future.  Minor changes are needed to use this for ERA, etc.
%
% L. Strow, June 11, 2014

% $$$ F.s_longitude = wrapTo360(ncread(fn_s,'longitude'));
F.s_longitude = circshift(wrapTo360(ncread(fn_s,'longitude')),288);
F.s_longitude(1) = 0.0;
F.s_latitude  = ncread(fn_s,'latitude');
% the merra surface variable collection is on an hourly time
% grid. hindex is based on era 6-hourly time gridding
tindex = 1 + (6*(hindex-1));
F.s_time      = ncread(fn_s,'time',[tindex],[1]);
% time dimension in merra data is relative to 00:00:00 on the day
% of so, extract yyyy/mm/dd from the filename and use as basis for
% time conversions
% merra filenames are like: YYYYMMDD_{sfc,lev}.nc
myear = str2num(fn_s(1:4));
mmonth = str2num(fn_s(5:6));
mday = str2num(fn_s(7:8));
F.s_mtime     = datenum(myear,mmonth,mday,0,double(F.s_time),0);


% We've already dealt with changing longitude fro [-180 180] to [0
% 360] t match era processing. lat range is inverted between era
% and merra but era processing uses a flipud which makes the lat
% range match the native merra order
[X,Y] = ndgrid(F.s_latitude,F.s_longitude);
% $$$ X=flipud(iX); Y=flipud(iY);

F.sp.ig   = griddedInterpolant(X,Y,...
                               single(circshift(ncread(fn_s,'sp',[1 1 tindex],[Inf Inf 1]),288,1))'/100,'linear');
F.skt.ig  = griddedInterpolant(X,Y,...
                               single(circshift(ncread(fn_s,'skt',[1 1 tindex],[Inf Inf 1]),288,1))','linear');
F.v10.ig  = griddedInterpolant(X,Y,...
                               single(circshift(ncread(fn_s,'v10',[1 1 tindex],[Inf Inf 1]),288,1))','linear');
F.u10.ig  = griddedInterpolant(X,Y,...
                               single(circshift(ncread(fn_s,'u10',[1 1 tindex],[Inf Inf 1]),288,1))','linear');
F.tcc.ig  = griddedInterpolant(X,Y,...
                               single(circshift(ncread(fn_s,'tcc',[1 1 tindex],[Inf Inf 1]),288,1))','linear');
F.ci.ig   = griddedInterpolant(X,Y,...
                               single(circshift(ncread(fn_s,'ci',[1 1 tindex],[Inf Inf 1]),288,1))','linear');

% $$$ F.h_longitude = wrapTo360(ncread(fn_h,'longitude'));
F.h_longitude = circshift(wrapTo360(ncread(fn_h,'longitude')),288);
F.h_longitude(1) = 0.0;
F.h_latitude  = ncread(fn_h,'latitude');
F.levid       = ncread(fn_h,'level');
% the merra levels variable collection is on a 3-hourly grid
tindex = 1 + (2*(hindex-1));
F.h_time      = ncread(fn_h,'time',[tindex],[1]);
% time dimension in merra data is minutes relative to 00:00:00 on the day
% of so, extract yyyy/mm/dd from the filename and use as basis for
% time conversions
% merra filenames are like: YYYYMMDD_{sfc,lev}.nc
myear = str2num(fn_h(1:4));
mmonth = str2num(fn_h(5:6));
mday = str2num(fn_h(7:8));
F.h_mtime     = datenum(myear,mmonth,mday,0,double(F.h_time),0);

% see note above on data order differences between era/merra
[X,Y] = ndgrid(F.h_latitude,F.h_longitude);
% $$$ X=flipud(iX); Y=flipud(iY);

t = permute(single(circshift(ncread(fn_h,'t',[1 1 1 tindex],[Inf Inf Inf 1]),288,1)),[2,1,3]);
for i=1:length(F.levid)
   F.t(i).ig = griddedInterpolant(X,Y,squeeze(t(:,:,i)),'linear');
end
clear t

ciwc = permute(single(circshift(ncread(fn_h,'ciwc',[1 1 1 tindex],[Inf Inf Inf 1]),288,1)),[2,1,3]);
for i=1:length(F.levid)
   F.ciwc(i).ig = griddedInterpolant(X,Y,squeeze(ciwc(:,:,i)),'linear');
end
clear ciwc

cc = permute(single(circshift(ncread(fn_h,'cc',[1 1 1 tindex],[Inf Inf Inf 1]),288,1)),[2,1,3]);
for i=1:length(F.levid)
   F.cc(i).ig = griddedInterpolant(X,Y,squeeze(cc(:,:,i)),'linear');
end
clear cc

q = permute(single(circshift(ncread(fn_h,'q',[1 1 1 tindex],[Inf Inf Inf 1]),288,1)),[2,1,3]);
for i=1:length(F.levid)
   F.q(i).ig = griddedInterpolant(X,Y,squeeze(q(:,:,i)),'linear');   
end
clear q

o3 = permute(single(circshift(ncread(fn_h,'o3',[1 1 1 tindex],[Inf Inf Inf 1]),288,1)),[2,1,3]);
for i=1:length(F.levid)
   F.o3(i).ig = griddedInterpolant(X,Y,squeeze(o3(:,:,i)),'linear');
end
clear o3

clwc = permute(single(circshift(ncread(fn_h,'clwc',[1 1 1 tindex],[Inf Inf Inf 1]),288,1)),[2,1,3]);
for i=1:length(F.levid)
   F.clwc(i).ig = griddedInterpolant(X,Y,squeeze(clwc(:,:,i)),'linear');
end
clear clwc

delp = permute(single(circshift(ncread(fn_h,'delp',[1 1 1 tindex],[Inf Inf Inf 1]),288,1)),[2,1,3]);
for i=1:length(F.levid)
   F.delp(i).ig = griddedInterpolant(X,Y,squeeze(delp(:,:,i)),'linear');
end
clear delp

% whos
