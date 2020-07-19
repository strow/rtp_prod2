function F = grib_interpolate(fn_s,fn_h);
% 
% Inputs: fn_s, fn_h
%         Netcdf files containing grib1 and grib2 
%         data respectively.  This code assumes the grib1 data
%         is surface data, and the grib2 data is hybrid ecmwf data.

% Output: F, a structure with housekeeping data (lat, lon of grid) and
%         interpolants for interpolating to arbitrary lat/lon positions.
%
% Presently the interpolant is set to be linear, you can also 
% select nearest-neighbor, cubic, etc.  I may make this an option
% in the future.  Minor changes are needed to use this for ERA, etc.
%
% L. Strow, June 11, 2014

F.s_longitude = ncread(fn_s,'longitude');
F.s_latitude  = ncread(fn_s,'latitude');
F.s_time      = ncread(fn_s,'time');
F.s_mtime     = datenum(1900,0,0,double(F.s_time),0,0);

[X,Y] = ndgrid(F.s_latitude,F.s_longitude);
iX = flipud(X); iY = flipud(Y);

F.sst.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'sst'))'),'linear');
try
   F.sp.ig   = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'sp'))'/100),'linear');
catch
   junk   = ncread(fn_h,'sp')/100;
   plot(1:60,squeeze(junk(360,180,:)),'o-'); title('HAHAH SPRES ON LEVELS HAHAHA')
   woof = squeeze(junk(360,180,:));
   woof = find(isfinite(woof)); 
   if length(woof) == 1
     fprintf(1,' >>> found SPRES is finite on hybrid level level %2i \n',woof);
   elseif length(woof) == 0
     error('>>> try catch did not find any HYBRID LEVELS where spres is finite')
   elseif length(woof) > 1
     error('>>> try catch found more than one HYBRID LEVELS where spres is finite')
   end
   junk = squeeze(junk(:,:,woof));
   F.sp.ig   = griddedInterpolant(iX,iY,flipud(single(junk')),'linear');
end
   
F.skt.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'skt'))'),'linear');
F.v10.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'v10'))'),'linear');
F.u10.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'u10'))'),'linear');
F.tcc.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'tcc'))'),'linear');
F.ci.ig   = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'ci'))'),'linear');
F.tcwv.ig = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'tcwv'))'),'linear');
F.msl.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'msl'))'),'linear');

F.h_longitude = ncread(fn_h,'longitude');
F.h_latitude  = ncread(fn_h,'latitude');
F.levid       = ncread(fn_h,'level');
F.h_time      = ncread(fn_h,'time');
F.h_mtime     = datenum(1900,0,0,double(F.h_time),0,0);

[X,Y] = ndgrid(F.h_latitude,F.h_longitude);
iX = flipud(X); iY = flipud(Y);

t = permute(single(ncread(fn_h,'t')),[2,1,3]);
for i=1:length(F.levid)
   F.t(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(t(:,:,i))),'linear');
end
clear t

ciwc = permute(single(ncread(fn_h,'ciwc')),[2,1,3]);
for i=1:length(F.levid)
   F.ciwc(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(ciwc(:,:,i))),'linear');
end
clear ciwc

cc = permute(single(ncread(fn_h,'cc')),[2,1,3]);
for i=1:length(F.levid)
   F.cc(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(cc(:,:,i))),'linear');
end
clear cc

q = permute(single(ncread(fn_h,'q')),[2,1,3]);
for i=1:length(F.levid)
   F.q(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(q(:,:,i))),'linear');   
end
clear q

o3 = permute(single(ncread(fn_h,'o3')),[2,1,3]);
for i=1:length(F.levid)
   F.o3(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(o3(:,:,i))),'linear');
end
clear o3

clwc = permute(single(ncread(fn_h,'clwc')),[2,1,3]);
for i=1:length(F.levid)
   F.clwc(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(clwc(:,:,i))),'linear');
end
clear clwc

% whos  % for debugging
