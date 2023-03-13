 function [head,hattr,prof] = fill_co2(head,hattr,prof);
%
%
%
%
%
%
%

addpath /home/chepplew/myLib/matlib/readers      % read_netcdf
addpath /home/chepplew/myLib/matlib/loaders      % read_netcdf
addpath /asl/matlib/time                 % tai2dnum

disp('fill_co2: adding CO2')
co2 = struct;

% for development save plots to these places:
tphome = '/home/chepplew/data/matlab/figs/';

% Load global average trend data (yyyy mm dd max min)
%      date-range: 2013.01.01 to 2023.02.27
co2.trend_fn = '/home/chepplew/data/GML_CO2/trends/co2_trend_gl.txt';
D = importdata(co2.trend_fn,' ',41);
co2.trdnum = datenum([D.data(:,1) D.data(:,2) D.data(:,3)]);
co2.trppmv = D.data(:,4);
clear D;

% ============================================
% CO2 NOAA GML data (glb3x2 CT2019B to 2019 then NRT from 2019 to 2021)
% ============================================
d(1).home = '/home/chepplew/data/GML_CO2/global/monthly/gml.noaa.gov/';
d(2).home = '/home/chepplew/data/GML_CO2/global/nrt/';
d(1).list = dir([d(1).home 'CT2019B*.nc']);
d(2).list = dir([d(2).home 'CT-NRT*.nc']);

% Extract datestring from the files
clear ddnum
for id=1:length(d(1).list)
  junk = d(1).list(id).name(end-9:end-3);
  ddnum(id) = datenum(junk,'yyyy-mm');
end
ik = id;
for id=1:length(d(2).list)
  ik = ik + 1;
  junk = d(2).list(id).name(end-12:end-3);
  ddnum(ik) = datenum(junk,'yyyy-mm-dd');
end
% there is file overlap 2019.Jan-Mar
ddnum = unique(ddnum);

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
%umn  = unique(month(rmtime));

% Load gridded GML data  
% 1 from 2000.01 to 2019.03  co2 [ 120x90x25 ]
% 2 from 2019.04.01 to 2021.02.01 [12x90x35x8]
if(mean(rmtime) < datenum('2019/03/01','yyyy/mm/dd'))
  % use d(1) monthly data
  junk = datenum([num2str(uyr(1)) '-' num2str(umn(1))],'yyyy-mm');
  iiddn = find(ddnum == junk);
  [sd att] = read_netcdf([d(1).list(1).folder '/' d(1).list(iiddn).name]);

elseif(mean(rmtime) >= datenum('2019/03/01','yyyy/mm/dd') & ...
       mean(rmtime) <= datenum('2021/02/01','yyyy/mm/dd'))
  % use d(2) first day of the month data
  junk = datenum([num2str(uyr(1)) '-' num2str(umn(1))],'yyyy-mm');
  iiddn = find(ddnum == junk);  
  [sd att] = read_netcdf([d(2).list(1).folder '/' d(2).list(iiddn-231+3).name]);

elseif(mean(rmtime) > datenum('2021/02/01','yyyy/mm/dd'))
  [sd att] = read_netcdf([d(2).list(end).folder '/' d(2).list(end).name]);

end

% NRT data are daily and have 4th dimension (hours) so trim if needed
co2.nlevs = length(sd.level);
% convert pressure to hPa
if(ndims(sd.pressure) == 4)
  co2.press = 0.01*mean(sd.pressure(:,:,1:co2.nlevs,:),4);
  co2.ppmv  = mean(sd.co2,4);
else
  co2.press = 0.01*sd.pressure;
  co2.ppmv  = sd.co2;
end

% ==============================================
% Interpolate reference values to obs locations
% ==============================================
clear iilat;
for i=1:length(sd.latitude)-1
  iilat{i} = find(prof.rlat >= sd.latitude(i) & prof.rlat < sd.latitude(i+1) );
end

% figure;hold on; for i=1:length(iilat) plot(prof.rlat(iilat{i}),'.');end
% fh1=figure('visible','off');hold on; 
%    for i=1:length(iilat) plot(prof.rlat(iilat{i}),'.');end
%    saveas(fh1,[tphome 'fill_co2_fig01.fig'],'fig');

[X,Y] = ndgrid(sd.longitude, sd.latitude);
iX    = flipud(X); iY = flipud(Y);

% 120 lon x 90 lat x [25,35] lev.
clear F
for i = 1:size(sd.co2,3)
  %%F.co2(i).ig = griddedInterpolant(iX,iY,flipud(single(sd.co2(:,:,i))),'linear');
  %%F.co2(i).ig = griddedInterpolant(Y',X',flipud(squeeze(sd.co2(:,:,i))),'linear');
  F.co2(i).ig = griddedInterpolant(X,Y,(squeeze(co2.ppmv(:,:,i))),'linear');
  %F.co2(i).ig = griddedInterpolant(X,Y,(squeeze(sd.co2(:,:,i))),'nearest');
end

% Assume rtp lat/lon are +-180??  Need to be 0-360 for interpolation
% loop over rlat,rlon
clear co2.intrp;
for isp = 1:length(prof.rlat)
   rlat = prof.rlat(isp);
   rlon = prof.rlon(isp);
   %rlat(rlat<0) = rlat(rlat<0) + 90;
   %rlon(rlon<0) = rlon(rlon<0) + 360;
   for ilv = 1:co2.nlevs
     co2.intrp(ilv,isp)  = F.co2(ilv).ig(rlon, rlat);
   end
end

% match region and condition some variables
%iia = find(sd.latitude > min(prof.rlat)-0.1 & sd.latitude < max(prof.rlat)+0.1);
%iin = find(sd.longitude > min(prof.rlon) & sd.longitude < max(prof.rlon));
%sd_co2_mn  = squeeze(nanmean(sd.co2(iin,iia,:),[1 2]));
%sd_co2_sd  = squeeze(nanstd(sd.co2(iin,iia,:),0,[1 2]));
%sd_prs_mn  = squeeze(nanmean(sd.pressure(iin,iia,:),[1 2]));
%res_co2_mn = squeeze(nanmean(res_co2,2));
%res_co2_sd = squeeze(nanstd(res_co2,0,2));


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
opt2 = struct;
opt2.latitude = nanmean(prof.rlat);
opt2.year     = uyr(1);
opt2.month    = umn(1);

atm = load_standard_atmos(opt2);

% ======================================================
% Account for CH4 change since reference atmosphere data
% ======================================================
% Extrapolate/interpolate from trend data to current time:
xvals = co2.trdnum - co2.trdnum(1);
xq    = datenum([uyr(1) umn(1) 1]) - co2.trdnum(1);
co2.upd = interp1(xvals, co2.trppmv, xq,'linear','extrap');

% Scale the AFGL std.ATM & co2.intrp profiles with updated surface value
co2.intxmr     = co2.upd/mean(co2.intrp(1,:),2);
co2.stdxmr     = co2.upd/atm.CO2(1);

% splice top part of std onto ERSL profile
% trap zero pressure at top of vector:
%%iipp = find( atm.PRE(:) <= min(nanmean(sd.pressure(:,:,1:end-1),[1 2])) );
iipp       = find( atm.PRE(:) <= min(nanmean(co2.press(:,:,1:co2.nlevs),[1 2])) );
ctop       = repmat(atm.CO2(iipp), 1, nprofs);
ptop       = repmat(atm.PRE(iipp), 1, nprofs);
co2.xtrp   = [co2.intxmr*co2.intrp; co2.stdxmr*ctop];

% Option: shift atm.CO2 to match value of co2.intrp at splice level.
% Mean values at top of ESRL profiles and at splice level of AFGL std.
co2_a = mean(co2.intxmr*co2.intrp(end,:),2);
co2_b = mean(co2.stdxmr*ctop(1,:),2);
co2_ab = co2_b - co2_a;
co2.xtrp   = [co2.intxmr*co2.intrp; co2.stdxmr*ctop - co2_ab];

  press_smn = squeeze(nanmean(co2.press(:,:,1:co2.nlevs),[1 2]));
co2.plevs  = repmat(press_smn,1,nprofs);
co2.plevs  = [co2.plevs; ptop];

% =====================================================================
% re-order and re-sample profiles for compliance with other ECMWF fields
% =====================================================================
co2.plevs   = co2.plevs(end:-1:1,:);
co2.newprof = co2.xtrp(end:-1:1,:);

%{
% add to previous profile plot

plot(nanmean(res2,2), nanmean(prs2,2),'g.-')

%}

% Interpolate to the 60-levels of the ECMWF fields
clear gas_2;
for i = 1:nprofs
  gas_2(:,i) = interp1(co2.plevs(:,i), co2.newprof(:,i), prof.plevs(:,i),'linear','extrap');
end

% update head and prof
head.ngas  = head.ngas + 1;
head.glist = [head.glist; 2];
head.gunit = [head.gunit; 10];   % ppmv dry air

prof.gas_2 = gas_2;


%{
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

%}

%{
fh3=figure('visible','off');hold on;
  plot(nanmean(pd2.gas_2,2), nanmean(pd2.plevs,2),'.-')
  plot(nanmean(pd2.gas_2,2) + nanstd(pd2.gas_2,0,2), nanmean(pd2.plevs,2),'.-')
  saveas(fh3,[tphome 'pd2_gas2_vs_press_mean_stdv_post_klayers.fig'],'fig')

%}
