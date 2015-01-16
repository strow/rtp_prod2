cd /asl/data/ecmwf/2013/08

fn_s_all = dir('UAD*-1.nc');
fn_h_all = dir('UAD*-2.nc');

fn_s = fn_s_all(1).name;
fn_h = fn_h_all(1).name;

s_longitude = ncread(fn_s,'longitude');
s_latitude  = ncread(fn_s,'latitude');
s_time      = ncread(fn_s,'time');
s_mtime     = datenum(1900,0,0,double(s_time),0,0);

[X,Y] = ndgrid(s_latitude,s_longitude);
iX = flipud(X); iY = flipud(Y);

F.sst.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'sst'))'),'linear');
F.sp.ig   = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'sp'))'),'linear');
F.skt.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'skt'))'),'linear');
F.v10.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'v10'))'),'linear');
F.u10.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'u10'))'),'linear');
F.tcc.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'tcc'))'),'linear');
F.ci.ig   = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'ci'))'),'linear');
F.tcwv.ig = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'tcwv'))'),'linear');
F.msl.ig  = griddedInterpolant(iX,iY,flipud(single(ncread(fn_s,'msl'))'),'linear');

h_longitude = ncread(fn_h,'longitude');
h_latitude  = ncread(fn_h,'latitude');
levid       = ncread(fn_h,'level');
h_time      = ncread(fn_h,'time');
h_mtime     = datenum(1900,0,0,double(h_time),0,0);

[X,Y] = ndgrid(h_latitude,h_longitude);
iX = flipud(X); iY = flipud(Y);

t = permute(single(ncread(fn_h,'t')),[2,1,3]);
for i=1:length(levid)
   F.t(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(t(:,:,i))),'linear');
end
clear t

ciwc = permute(single(ncread(fn_h,'ciwc')),[2,1,3]);
for i=1:length(levid)
   F.ciwc(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(ciwc(:,:,i))),'linear');
end
clear ciwc

cc = permute(single(ncread(fn_h,'cc')),[2,1,3]);
for i=1:length(levid)
   F.cc(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(cc(:,:,i))),'linear');
end
clear cc

q = permute(single(ncread(fn_h,'q')),[2,1,3]);
for i=1:length(levid)
   F.q(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(q(:,:,i))),'linear');   
end
clear q

o3 = permute(single(ncread(fn_h,'o3')),[2,1,3]);
for i=1:length(levid)
   F.o3(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(o3(:,:,i))),'linear');
end
clear o3

clwc = permute(single(ncread(fn_h,'clwc')),[2,1,3]);
for i=1:length(levid)
   F.clwc(i).ig = griddedInterpolant(iX,iY,flipud(squeeze(clwc(:,:,i))),'linear');
end
clear clwc

%p.sst = F.sst.ig(p.rlat,p.rlon);


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