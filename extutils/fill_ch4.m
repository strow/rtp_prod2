 function [head,hattr,prof] = fill_ch4(head,hattr,prof)
%
% Start with CH4 distribution at time 0 ref: 2010.Dec
% Get growth rate from annual mean values file
% Get mean time for required sample period and adjust ref. value
%     by fractional growth over time interval.
% Load the standard atmosphere and splice profile on top.
%

addpath /home/chepplew/myLib/matlib/readers      % read_netcdf
addpath /home/chepplew/myLib/matlib/loaders      % load_standard_atmos

disp('fill_ch4.m: adding CH4')

% =============================================
% Load Reference CH4 distribution at 2010.12.31
% =============================================
ch4.ref_fn = '/home/chepplew/data/GML_CH4/ch4_molefractions/20101231.nc';

[sac aac] = read_netcdf(ch4.ref_fn);

% Total CH4 ppbv
ch4.tot = sac.bgrnd + sac.fossil + sac.agwaste + sac.natural + sac.bioburn + sac.ocean;

% Get global mean (near) surface ppbv at this reference point:
ch4.gbl_mn0 = mean(ch4.tot(:,:,1:3,:),[1 2 3 4]);

% Average the 8 time & longitude samples and get the number of levels:
ch4.tot_tmn = squeeze(nanmean(ch4.tot,4));
ch4.nlevs   = size(sac.pressure,3);

% ============================================
% Load CH4 global annual mean trend from file:
% ============================================
fn_gbl_amn = '/home/chepplew/data/GML_CH4/trends/ch4_annmean_gl.txt';
D = importdata(fn_gbl_amn,' ',62);
ch4.annmean  = D.data(:,2);
ch4.annyrs   = datenum(num2str(D.data(:,1)),'yyyy');   % ! January or June?
 
% ch4.annmean(2011) ought to be close to ch4.gbl_mn0 at 2010.12.31

% Sample AIRS granule
%hdf_fn='/asl/airs/l1c_v672/2019/018/AIRS.2019.01.18.001.L1C.AIRS_Rad.v6.7.2.0.G19360072949.hdf';
%[head,hattr,prof,pattr] = airs_l1c_to_rtp(hdf_fn,0);

% allocate memory for gas_6 (CH4)
nprofs     = size(prof.plevs,2);
prof.gas_6 = NaN(size(prof.plevs));

% Get time information for obs.
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

% ==============================================
% Interpolate reference values to obs locations
% ==============================================
clear iilat;
for i=1:length(sac.lat)-1
  iilat{i} = find(prof.rlat >= sac.lat(i) & prof.rlat < sac.lat(i+1) );
end

% figure;hold on; for i=1:44 plot(prof.rlat(iilat{i}),'.');end

[X,Y] = ndgrid(sac.lon, sac.lat);
iX    = flipud(X); iY = flipud(Y);

% 60 x lon, 45 x lat, 34 x lev, 8 x time
clear F
for i = 1:size(ch4.tot_tmn,3)
  %%F.ch4(i).ig = griddedInterpolant(iX,iY,flipud(single(sd.tot_mn(:,:,i))),'linear');
  %%F.ch4(i).ig = griddedInterpolant(Y',X',flipud(squeeze(sd.tot_mn(:,:,i))),'linear');
  F.ch4(i).ig = griddedInterpolant(X,Y,(squeeze(ch4.tot_tmn(:,:,i))),'linear');
  %F.ch4(i).ig = griddedInterpolant(X,Y,(squeeze(sd.tot_mn(:,:,i))),'nearest');
end

% Assume rtp lat/lon are +-180??  Need to be 0-360 for interpolation
% loop over rlat,rlon
clear ch4.intrp;
for isp = 1:length(prof.rlat)
   rlat = prof.rlat(isp);
   rlon = prof.rlon(isp);
   %rlat(rlat<0) = rlat(rlat<0) + 90;
   %rlon(rlon<0) = rlon(rlon<0) + 360;
   for ilv = 1:ch4.nlevs
     ch4.intrp(ilv,isp)  = F.ch4(ilv).ig(rlon, rlat);
   end
end
   
%{
 simplemap(prof.rlat, prof.rlon, ch4.intrp(2,:), 0.2,'lat',[0 40], 'lon',[-180 -130])
 simplemap(prof.rlat, prof.rlon, ch4.intrp(20,:),0.2,'lat',[0 40], 'lon',[-180 -130])

plot(squeeze(ch4.tot_tmn(4,27,:)),squeeze(sac.pressure(4,27,:,4)),'.-')
  hold on;plot(squeeze(ch4.tot_tmn(4,32,:)),squeeze(sac.pressure(4,32,:,4)),'.-')
  set(gca,'YScale','log');set(gca,'YDir','reverse');grid on;ylim([0.05 1100])
  plot(ch4.res(:,923),   squeeze(sac.pressure(4,32,:,4)),'c.-')
  plot(ch4.res(:,10046), squeeze(sac.pressure(4,32,:,4)),'m.-')

 junk = permute(ch4.tot_tmn(:,:,2),[2 1]);
  [uuu vvv] = ndgrid(sac.lat, sac.lon);
 simplemap(uuu, vvv, junk, 2.0)
%}


% match region and condition some variables
%iiaa = find(sac.lat > min(prof.rlat) & sac.lat < max(prof.rlat));
%iibb = find(sac.lon > min(prof.rlon) & sac.lon < max(prof.rlon));
%sd_ch4_mn  = squeeze(nanmean(ch4.tot_tmn(iibb,iiaa,:),[1 2]));
%sd_ch4_sd  = squeeze(nanstd(ch4.tot_tmn(iibb,iiaa,:),0,[1 2]));
%sd_prs_mn  = squeeze(nanmean(sac.pressure(iibb,iiaa,1:end-1),[1 2]));
%ch4.res_mn = squeeze(nanmean(ch4.res,2));
%ch4.res_sd = squeeze(nanstd(ch4.res,0,2));

%rlat_mn       = nanmean(prof.rlat);
%xpress_tmn = nanmean(sac.pressure,4);

% ====================================================================
% Load up most appropriate standard atmosphere to tack on upper levels
% ====================================================================
opt2 = struct;
opt2.latitude = nanmean(prof.rlat);
opt2.year     = uyr;
opt2.month    = umn;

atm = load_standard_atmos(opt2);

% splice top part of std onto ERSL profile to make new array 'xtrp'
iipp       = find( atm.PRE(:) <= min(nanmean(sac.pressure(:,:,1:end-1),[1 2])) );
ctop       = repmat(1E3*atm.CH4(iipp), 1, nprofs);
ptop       = repmat(atm.PRE(iipp), 1, nprofs); 
ch4.xtrp   = [ch4.intrp; ctop];
  sac_press_smn = squeeze(nanmean(sac.pressure,[1 2 4]));
ch4.press  = repmat(sac_press_smn,1,nprofs);
ch4.press  = [ch4.press; ptop];

%hold on; plot(res2(:,923), prs2(:,923),'b.-')

% ======================================================
% Account for CH4 change since reference atmosphere data
% ======================================================
% Extrapolate/interpolate from trend data to current time:
xvals = ch4.annyrs - ch4.annyrs(1);
xq    = datenum([uyr(1) umn(1) 1]) - ch4.annyrs(1);
ch4.upd = interp1(xvals, ch4.annmean, xq,'linear','extrap');

% Try a fractional adjustment to nearest year
%frac_yr     = (mean(rmtime) - datenum('2010/12/01','yyyy/mm/dd'))/365.25;
%[tdiff jjd] = min(abs(ch4.annyrs - mean(rmtime)) );
%frac_ch4    = (ch4.annmean(jjd) - ch4.annmean(27))/ch4.annmean(27);
%ch4.res3    = (1 + frac_ch4)*ch4.res2;

% Scale the xtrp profiles with updated surface value
ch4.scale   = ch4.upd/ch4.gbl_mn0;
ch4.newprof = ch4.scale*ch4.xtrp;

% =====================================================================
% re-order and re-sample profiles for comliance with other ECMWF fields
% =====================================================================
% reverse ordering of pressure (TOA to SFC)
ch4.press   = ch4.press(end:-1:1,:);
ch4.newprof = ch4.newprof(end:-1:1,:);

% Interpolate to the ECMWF levels (60,91)
clear gas_6;
for i = 1:nprofs
  gas_6(:,i) = interp1(ch4.press(:,i), ch4.newprof(:,i), ...
               prof.plevs(:,i),'pchip',ch4.newprof(end,i));
end

% update head and prof
head.ngas  = head.ngas + 1;
head.glist = [head.glist; 6];
head.gunit = [head.gunit; 11];

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

