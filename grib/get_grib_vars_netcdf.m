cd /asl/s1/strow/Grib_tools

% ds = read_netcdf_lls('surface.nc');
% dh = read_netcdf_lls('hybrid.nc');

fn_s = 'surface2.nc';
fn_h = 'hybrid2.nc';

s_longitude = ncread(fn_s,'longitude');
s_latitude  = ncread(fn_s,'latitude');
s_time      = ncread(fn_s,'time');
s_mtime     = datenum(1900,0,0,double(s_time),0,0);

sst  = single(ncread(fn_s,'sst'))';
sp   = single(ncread(fn_s,'sp'))';
skt  = single(ncread(fn_s,'skt'))';
v10  = single(ncread(fn_s,'v10'))';
u10  = single(ncread(fn_s,'u10'))';
tcc  = single(ncread(fn_s,'tcc'))';
ci   = single(ncread(fn_s,'ci'))';
tcwv = single(ncread(fn_s,'tcwv'))';
msl  = single(ncread(fn_s,'msl'))';

h_longitude = ncread(fn_h,'longitude');
h_latitude  = ncread(fn_h,'latitude');
levid       = ncread(fn_h,'level');
h_time      = ncread(fn_h,'time');
h_mtime     = datenum(1900,0,0,double(h_time),0,0);

t     = permute(single(ncread(fn_h,'t')),[2,1,3]);
ciwc  = permute(single(ncread(fn_h,'ciwc')),[2,1,3]);
cc    = permute(single(ncread(fn_h,'cc')),[2,1,3]);
q     = permute(single(ncread(fn_h,'q')),[2,1,3]);
o3    = permute(single(ncread(fn_h,'o3')),[2,1,3]);
clwc  = permute(single(ncread(fn_h,'clwc')),[2,1,3]);

% Read in a rtp file.

iX = flipud(X); iY = flipud(Y);
% Fast resusable interpolation
[X,Y] = ndgrid(s_latitude,s_longitude);

F.sst.ig = griddedInterpolant(iX,iY,flipud(sst),'linear');
F.sp.ig = griddedInterpolant(iX,iY,flipud(sp),'linear');
F.skt.ig = griddedInterpolant(iX,iY,flipud(skt),'linear');
F.v10.ig = griddedInterpolant(iX,iY,flipud(v10),'linear');
F.u10.ig = griddedInterpolant(iX,iY,flipud(u10),'linear');
F.tcc.ig = griddedInterpolant(iX,iY,flipud(tcc),'linear');
F.ci.ig = griddedInterpolant(iX,iY,flipud(ci),'linear');
F.tcwv.ig = griddedInterpolant(iX,iY,flipud(tcwv),'linear');
F.msl.ig = griddedInterpolant(iX,iY,flipud(msl),'linear');

for i=1:length(levid)
   ilev = levid(i);
   F.t(ilev).ig = griddedInterpolant(iX,iY,flipud(squeeze(t(:,:,ilev))),'linear');
   F.t(ilev).ig = griddedInterpolant(iX,iY,flipud(squeeze(t(:,:,ilev))),'linear');
   F.ciwc(ilev).ig = griddedInterpolant(iX,iY,flipud(squeeze(ciwc(:,:,ilev))),'linear');
   F.cc(ilev).ig = griddedInterpolant(iX,iY,flipud(squeeze(cc(:,:,ilev))),'linear');
   F.q(ilev).ig = griddedInterpolant(iX,iY,flipud(squeeze(q(:,:,ilev))),'linear');
   F.o3(ilev).ig = griddedInterpolant(iX,iY,flipud(squeeze(o3(:,:,ilev))),'linear');
   F.clwc(ilev).ig = griddedInterpolant(iX,iY,flipud(squeeze(clwc(:,:,ilev))),'linear');
end

clear t ciwc cc q o3 clwc sst sp skt v10 u10 tcc ci tcwv msl


%p.sst = F.sst(p.rlat,p.rlon);


% p.sst = interp2(s_longitude,s_latitude,single(sst'),p.rlon,p.rlat,'cubic');

%for levid = 1:le

   %p.ptemp(find

% Plot some level of temperatures:
% imagesc(squeeze(hdata{1}(:,:,30)'))

% 
% dl = ds.longitude;
% k = find(dl > 179.9);
% dl(k) = dl(k)-2*180;
% pcolor(ds.longitude(i),ds.latitude,y(:,i));shading flat;
% [b,i]=sort(dl);
% pcolor(dl(i),ds.latitude,y(:,i));shading flat;
% 
% y = y.*5.25E-4+287.3074;
% 
% y = sst';