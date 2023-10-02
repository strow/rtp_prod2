 function [head,hattr,prof] = fill_ch4_cams(head,hattr,prof)
%
% Based on fill_ch4.m except using monthly mean global profiles from CAMS.
% Match time and location to monthly file.
% 
% 
% Load the standard atmosphere and splice profile on top.
%

addpath /home/chepplew/myLib/matlib                    % read_netcdf
addpath /home/chepplew/myLib/matlib/convert_gas_units  % toppmv.m
 
disp('fill_ch4.m: adding CH4')

% Home of the CAMS CH4 monthly means
% 
ch4.home = '/home/chepplew/data/tmp_egg4/';
ch4.list = dir([ch4.home '*co2_ch4.nc']);


% Sample AIRS granule
%hdf_fn='/asl/airs/l1c_v672/2019/018/AIRS.2019.01.18.001.L1C.AIRS_Rad.v6.7.2.0.G19360072949.hdf';

%[head,hattr,prof,pattr] = airs_l1c_to_rtp(hdf_fn,0);

% allocate memory for gas_6 (CH4)
nprofs     = size(prof.plevs,2);
prof.gas_6 = NaN(size(prof.plevs));

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

uyrmon = sprintf('%4d%02d', uyr,umn);

% Get CAMS file for this date:
% if outside available date range use nearest year and include multiplier
for i=1:length(ch4.list)
  junk = strsplit(ch4.list(i).name,{'_','.'});
  cams_yrmon(i) = datenum(junk{1},'yyyymm');
end
if( datenum(uyrmon,'yyyymm') <= datenum('202012','yyyymm') & ...
    datenum(uyrmon,'yyyymm') >= datenum('200401','yyyymm') ) 
    iifn = find(cams_yrmon == datenum(uyrmon,'yyyymm'));
    ch4.multi = 1.000;
elseif( datenum(uyrmon,'yyyymm') > datenum('202012','yyyymm') )
    uyrmon = sprintf('%4d%02d', 2020,umn);
    iifn = find(cams_yrmon == datenum(uyrmon,'yyyymm'));
    ch4.multi = 1.004;
elseif( datenum(uyrmon,'yyyymm') < datenum('200301','yyyymm') )
        uyrmon = sprintf('%4d%02d', 2004,umn);
    iifn = find(cams_yrmon == datenum(uyrmon,'yyyymm'));
    ch4.multi = 0.996;
end

ch4.fname = [ch4.list(iifn).folder '/' ch4.list(iifn).name];

ch4.mmr  = ncread(ch4.fname,'ch4');          % MMR
ch4.tem  = ncread(ch4.fname,'t');
ch4.lat  = ncread(ch4.fname,'latitude');
ch4.lon  = ncread(ch4.fname,'longitude');    
ch4.lev  = ncread(ch4.fname,'level');        % mb TOA->SFC

% convert CAMS CH4 MMR to ppmv (same as std. atmos. profile)
% and apply multiplier (for early/late dates)
ch4.ppmv = ch4.multi*toppmv(ch4.lev, ch4.tem, ch4.mmr, 16.04,21);

% for gridding matchups need to swap latitude to be ascending -90:90
ch4.lat  = ch4.lat(end:-1:1);
ch4.ppmv = ch4.ppmv(:,end:-1:1,:);
% and ECMWF longitude from 0:360 to -180:180
[ch4.lon, islon] = sort(wrapTo180(ch4.lon));
%%%ch4.lon = ch4.lon(end:-1:1);
ch4.ppmv = ch4.ppmv(islon,:,:);

clear iilat;
for i=1:length(ch4.lat)-1
  iilat{i} = find(prof.rlat >= ch4.lat(i) & prof.rlat < ch4.lat(i+1) );
end
% figure;hold on; for i=1:240 plot(prof.rlat(iilat{i}),'.');end


[X,Y] = ndgrid(ch4.lon, ch4.lat);
iX = flipud(X); iY = flipud(Y);

% 480 x lon, 241 x lat, 25 x lev
clear F
for i = 1:length(ch4.lev)
  %%F.ch4(i).ig = griddedInterpolant(iX,iY,flipud(single(sd.tot_mn(:,:,i))),'linear');
  %%F.ch4(i).ig = griddedInterpolant(Y',X',flipud(squeeze(sd.tot_mn(:,:,i))),'linear');
  F.ch4(i).ig = griddedInterpolant(X,Y,(squeeze(ch4.ppmv(:,:,i))),'linear');
  %F.ch4(i).ig = griddedInterpolant(X,Y,(squeeze(sd.tot_mn(:,:,i))),'nearest');
end

% Assume rtp lat/lon are +-180??  Need to be 0-360 for interpolation
% loop over rlat,rlon
clear ch4.res;
for isp = 1:length(prof.rlat)
   rlat = prof.rlat(isp);
   rlon = prof.rlon(isp);
   %rlat(rlat<0) = rlat(rlat<0) + 90;
   %rlon(rlon<0) = rlon(rlon<0) + 360;

   for ilv = 1:length(ch4.lev)
     ch4.res(ilv,isp)  = F.ch4(ilv).ig(rlon, rlat);
   end
end
   
%{
 simplemap(prof.rlat, prof.rlon, ch4.res(2,:), 0.2,'lat',[0 40], 'lon',[-180 -130])
 simplemap(prof.rlat, prof.rlon, ch4.res(20,:),0.2,'lat',[0 40], 'lon',[-180 -130])

plot(squeeze(ch4.tot_tmn(4,27,:)),squeeze(sac.pressure(4,27,:,4)),'.-')
  hold on;plot(squeeze(ch4.tot_tmn(4,32,:)),squeeze(sac.pressure(4,32,:,4)),'.-')
  set(gca,'YScale','log');set(gca,'YDir','reverse');grid on;ylim([0.05 1100])
  plot(ch4.res(:,923),   squeeze(sac.pressure(4,32,:,4)),'c.-')
  plot(ch4.res(:,10046), squeeze(sac.pressure(4,32,:,4)),'m.-')

 junk = permute(ch4.tot_tmn(:,:,2),[2 1]);
  [uuu vvv] = ndgrid(sac.lat, sac.lon);
 simplemap(uuu, vvv, junk, 2.0)
%}

% Load up most appropriate standard atmosphere to tack on upper levels


% match region and condition some variables
ch4.res_mn = squeeze(nanmean(ch4.res,2));
ch4.res_sd = squeeze(nanstd(ch4.res,0,2));

rlat_mn       = nanmean(prof.rlat);

opts = struct;
opts.latitude = rlat_mn;
opts.year     = uyr;
opts.month    = umn;

atm = load_standard_atmos(opts);

% splice top part of std onto ERSL profile - beware ordering.
iipp = find( atm.PRE(:) <= min(ch4.lev) );

[press isprs]  = sort([double(ch4.lev); atm.PRE(iipp)]);
ch4.press      = repmat(press,1,nprofs);
ctop           = repmat(atm.CH4(iipp),1,nprofs);
res2           = [ch4.res; ctop];
ch4.res2       = res2(isprs,:);

%hold on; plot(res2(:,923), prs2(:,923),'b.-')
%{
% Account for CH4 growth since reference atmosphere data
% Several ways to grow CH4 - but for now do a fractional adjustment to nearest year
frac_yr     = (mean(rmtime) - datenum('2010/12/01','yyyy/mm/dd'))/365.25;
[tdiff jjd] = min(abs(ch4.annyrs - mean(rmtime)) );
frac_ch4    = (ch4.annmean(jjd) - ch4.annmean(27))/ch4.annmean(27);
ch4.res3    = (1 + frac_ch4)*ch4.res2;
%}

% reverse ordering of pressure (TOA to SFC)
%%ch4.press   = ch4.press(end:-1:1,:);
%%ch4.res2    = ch4.res2(end:-1:1,:);


% Interpolate to the 60-levels of the ECMWF fields
clear gas_6;
for i = 1:nprofs
  gas_6(:,i) = interp1(ch4.press(:,i), ch4.res2(:,i), prof.plevs(:,i),'pchip',ch4.res2(end,i));
end

%{
% Interpolate to the 101-AIRS levels
aaa = importdata('/home/chepplew/myLib/data/airs_plevs.txt');
aaa = aaa'; aaa = aaa(:);
aaa(isnan(aaa)) = [];
airs_levs = aaa;  clear aaa;
clear gas_6;
for i = 1:nprofs
  %gas_6(:,i) = interp1(ch4.press(:,i), ch4.res2(:,i), airs_levs,'pchip',ch4.res2(end,i));
  gas_6(:,i) = interp1(ch4.press(:,i), ch4.res2(:,i), airs_levs,'pchip','extrap');
end
%}

% update head and prof
head.ngas  = head.ngas + 1;
head.glist = [head.glist; 6];
head.gunit = [head.gunit; 10];   % ! ppmv

prof.gas_6 = gas_6;

%{
% !!!! for stand-alone testing purposes only !!!!
% Pass through klayers

klayers_exec  = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';

% Save file and copy raw rtp data.
[sID, sTempPath] = genscratchpath();
fn_rtp1 = fullfile(sTempPath, ['airs_' sID '_1.rtp']);
fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);

rtpwrite(fn_rtp1,head,hattr,prof,pattr)
%hd0 = head;
%ha0 = hattr;
%pd0 = prof;
%pa0 = pattr;

klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               '/home/chepplew/logs/klayers/klout.txt'];
% Now run klayers
unix(klayers_run);

[hd2,ha2,pd2,pa2] = rtpread(fn_rtp2);

if(fn_rtp1) clear(fn_rtp1); end
if(fn_rtp2) clear(fn_rtp2); end

clear sd_* opts nprofs hd2 ha2 pd2 pa2 ch4 

%}

