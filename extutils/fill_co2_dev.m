% function [head,hattr,prof] = fill_co2(head,hattr,prof);
%
%
%
%
%
%
%

addpath /home/chepplew/myLib/matlib      % read_netcdf

% for development save plots to these places:
tphome = '/home/chepplew/data/matlab/figs/';

% Get std atmosphere
% <TBD>

% home of CO2 NOAA GML data
d.home = '/home/chepplew/data/GML_CO2/global/monthly/gml.noaa.gov/';

% Sample AIRS granule
hdf_fn='/asl/airs/l1c_v672/2019/018/AIRS.2019.01.18.001.L1C.AIRS_Rad.v6.7.2.0.G19360072949.hdf';

%[head,hattr,prof,pattr] = airs_l1c_to_rtp(hdf_fn,0);

% allocate memory for gas_2 (CO2)
nprofs     = size(prof.plevs,2);
prof.gas_2 = NaN(size(prof.plevs));

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

d.fname = [d.home 'CT2019B.molefrac_glb3x2_' ...
           sprintf('%04d-%02d',uyr(1),umn(1)) '.nc'];

[sd att] = read_netcdf(d.fname);

sd.nlevs = length(sd.level);
% convert pressure to hPa
sd.pressure = 0.01*sd.pressure;

% match to prof locations

clear iilat;
for i=1:length(sd.latitude)-1
  iilat{i} = find(prof.rlat >= sd.latitude(i) & prof.rlat < sd.latitude(i+1) );
end

% figure;hold on; for i=1:length(iilat) plot(prof.rlat(iilat{i}),'.');end
% fh1=figure('visible','off');hold on; 
%    for i=1:length(iilat) plot(prof.rlat(iilat{i}),'.');end
%    saveas(fh1,[tphome 'fill_co2_fig01.fig'],'fig');

[X,Y] = ndgrid(sd.longitude, sd.latitude);
iX = flipud(X); iY = flipud(Y);

% 120 lon x 90 lat x 25 lev.
clear F
for i = 1:size(sd.co2,3)
  %%F.co2(i).ig = griddedInterpolant(iX,iY,flipud(single(sd.co2(:,:,i))),'linear');
  %%F.co2(i).ig = griddedInterpolant(Y',X',flipud(squeeze(sd.co2(:,:,i))),'linear');
  F.co2(i).ig = griddedInterpolant(X,Y,(squeeze(sd.co2(:,:,i))),'linear');
  %F.co2(i).ig = griddedInterpolant(X,Y,(squeeze(sd.co2(:,:,i))),'nearest');
end

% Assume rtp lat/lon are +-180??  Need to be 0-360 for interpolation
% loop over rlat,rlon
clear res_co2;
for isp = 1:length(prof.rlat)
   rlat = prof.rlat(isp);
   rlon = prof.rlon(isp);
   %rlat(rlat<0) = rlat(rlat<0) + 90;
   %rlon(rlon<0) = rlon(rlon<0) + 360;

   for ilv = 1:sd.nlevs
     res_co2(ilv,isp)  = F.co2(ilv).ig(rlon, rlat);
   end
end

% match region and condition some variables
iia = find(sd.latitude > min(prof.rlat) & sd.latitude < max(prof.rlat));
iin = find(sd.longitude > min(prof.rlon) & sd.longitude < max(prof.rlon));
sd_co2_mn  = squeeze(nanmean(sd.co2(iin,iia,:),[1 2]));
sd_co2_sd  = squeeze(nanstd(sd.co2(iin,iia,:),0,[1 2]));
sd_prs_mn  = squeeze(nanmean(sd.pressure(iin,iia,1:end-1),[1 2]));
res_co2_mn = squeeze(nanmean(res_co2,2));
res_co2_sd = squeeze(nanstd(res_co2,0,2));


%{
simplemap(Y(:), X(:), sd.co2(:,:,1),3)
simplemap(prof.rlat, prof.rlon, res_co2(:,:,1))
simplemap(prof.rlat, prof.rlon, res_co2(1,:),0.2,'lat',[0 40],'lon',[-180 -120])

fh2=figure('visible','off'); hold on;
 plot(sd_co2_mn, sd_prs_mn,'b.-');
   plot(sd_co2_mn+sd_co2_sd, sd_prs_mn,'c.-')
   plot(sd_co2_mn-sd_co2_sd, sd_prs_mn,'c.-')
   plot(res_co2_mn, sd_prs_mn,'r.-')
   plot(res_co2_mn+res_co2_sd, sd_prs_mn,'m.-')
   plot(res_co2_mn-res_co2_sd, sd_prs_mn,'m.-')
   set(gca,'YDir','reverse');set(gca,'Yscale','log')
   saveas(fh2,[tphome 'sd_co2_mn_stdv_vs_press.fig'],'fig')

%}


% Load up most appropriate standard atmosphere to tack on upper levels

rlat_mn    = nanmean(prof.rlat);

opts = struct;
opts.latitude = rlat_mn;
opts.year     = uyr;
opts.month    = umn;

atm = load_standard_atmos(opts);

% splice top part of std onto ERSL profile
iip = find( atm.PRE(:) <= min(nanmean(sd.pressure(:,:,1:end-1),[1 2])) );

ctop = repmat(atm.CO2(iip), 1, nprofs);
ptop = repmat(atm.PRE(iip), 1, nprofs); 
res2 = res_co2;
res2 = [res2; ctop];
prs2 = repmat(sd_prs_mn,1,nprofs);
prs2 = [prs2; ptop];

% Account for CO2 growth since standard atmosphere data
% Several ways to grow CO2 - but for now do a fractional adjustment
coff  = res_co2_mn(end) - atm.CO2(iip(1));
cfrc  = (atm.CO2(iip(1)) + coff)/atm.CO2(iip(1));
ctop2 = cfrc * repmat(atm.CO2(iip), 1, nprofs);
res2  = res_co2;
res2  = [res2; ctop2];

% reverse ordering of pressure (TOA to SFC)
prs2(end:-1:1,:) = prs2(1:end,:);
res2(end:-1:1,:) = res2(1:end,:);

%{
% add to previous profile plot

plot(nanmean(res2,2), nanmean(prs2,2),'g.-')

%}

% Interpolate to the 60-levels of the ECMWF fields
clear gas_2;
for i = 1:nprofs
  gas_2(:,i) = interp1(prs2(:,i), res2(:,i), prof.plevs(:,i));
end

% update head and prof
head.ngas  = 3;
head.glist = [head.glist; 2];
head.gunit = [head.gunit; 10];   % ppmv dry air

prof.gas_2 = gas_2;

% Pass through klayers
klayers_exec  = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';

% Save file and copy raw rtp data.
[sID, sTempPath] = genscratchpath();
fn_rtp1 = fullfile(sTempPath, ['airs_' sID '_1.rtp']);
rtpwrite(fn_rtp1,head,hattr,prof,pattr)
hd0 = head;
ha0 = hattr;
pd0 = prof;
pa0 = pattr;

fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);
klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               '/home/chepplew/logs/klayers/klout.txt'];
% Now run klayers
unix(klayers_run);

[hd2,ha2,pd2,pa2] = rtpread(fn_rtp2);

%{
fh3=figure('visible','off');hold on;grid on

  plot(nanmean(pd2.gas_2,2), nanmean(pd2.plevs,2),'.-')
  plot(nanmean(pd2.gas_2,2) + nanstd(pd2.gas_2,0,2), nanmean(pd2.plevs,2),'.-')
  set(gca,'YDir','reverse');set(gca,'YScale','log');set(gca,'XScale','log')
  saveas(fh3,[tphome 'pd2_gas2_vs_press_mean_stdv_post_klayers.fig'],'fig')

