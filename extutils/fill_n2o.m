 function [head,hattr,prof] = fill_n2o(head,hattr,prof)
%
% Start with N2O profile at time 0 ref: <TBD>
% Get growth rate from annual mean values file
% Get mean time for required sample period and adjust ref. value
%     by fractional growth over time interval.
% Load the standard atmosphere and splice profile on top.
%

addpath /home/chepplew/myLib/matlib/readers      % read_netcdf
addpath /asl/matlib/h4tools

disp('fill_n2o.m: adding N2O')

% Get Reference N2O 
n2o.ref_fn = '/asl/packages/klayersV205/Data/adafgl_16Aug2010_ip.rtp';

% Load N2O profiles from file:
[~,~,pdn,~]  = rtpread(n2o.ref_fn);
n2o.refprofs = pdn.gas_4;
n2o.refplevs = pdn.plevs;
n2o.refdate  = datenum('2010/08/16','yyyy/mm/dd');
clear pdn; 
 
% Get the annual growth data
n2o.ann_fn = '/home/chepplew/data/GML_N2O/n2o_annmean_gl.txt';
junk = importdata(n2o.ann_fn,' ' ,62);
n2o.annmean = junk.data(:,2);
n2o.annyrs  = junk.data(:,1);
clear junk;

% Sample AIRS granule
%hdf_fn='/asl/airs/l1c_v672/2019/018/AIRS.2019.01.18.001.L1C.AIRS_Rad.v6.7.2.0.G19360072949.hdf';

%[head,hattr,prof,pattr] = airs_l1c_to_rtp(hdf_fn,0);

% allocate memory for gas_4 (N2O)
nprofs     = size(prof.plevs,2);
prof.gas_4 = NaN(size(prof.plevs));

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

% Get lat/lon centroid
lat_mn  = nanmean(prof.rlat(:));
lon_mn  = nanmean(prof.rlon(:));

% The 6 ref.profiles are: trop,mls,mlw,sas,saw,std so need to match them: 
all_prftyps = {'trop','mls','mlw','sas','saw','std'};
prftyp = [];
if(ismember(umn,[1,2,3,10,11,12]))
  if (lat_mn > 30 & lat_mn < 60)        prftyp = 'mlw';
  elseif (lat_mn < -30 & lat_mn > -60)  prftyp = 'mls';
  end
end
if(ismember(umn,[4,5,6,7,8,9]))
  if (lat_mn > 30 & lat_mn < 60)        prftyp = 'mls';
  elseif (lat_mn < -30 & lat_mn > -60)  prftyp = 'mlw';
  end
end
if(ismember(umn,[1,2,3,10,11,12]))
  if (lat_mn >= 60 & lat_mn <= 90)        prftyp = 'saw';
  elseif (lat_mn <= -60 & lat_mn >= -90)  prftyp = 'sas';
  end
end
if(ismember(umn,[4,5,6,7,8,9]))
  if (lat_mn >= 60 & lat_mn <= 90)        prftyp = 'sas';
  elseif (lat_mn <= -60 & lat_mn >= -90)  prftyp = 'saw';
  end
end
if (lat_mn <= 30 & lat_mn >= -30)       prftyp = 'trop';
end
if(isempty(prftyp)) 
  warning('unable to match time/lat for N2O using U.S. std')
  prftyp='std';
end

% match to prof lat/season & select required reference profile
iiprf       = find(contains(all_prftyps, prftyp));
n2o.refprof = n2o.refprofs(:,iiprf);

% Account for N2O change
% Extrapolate/interpolate from trend data to current time:
xvals = n2o.annyrs - n2o.annyrs(1);
xq    = uyr(1) + umn(1)/12 - n2o.annyrs(1);
n2o.upd = interp1(xvals, n2o.annmean, xq,'linear','extrap');

%{
% Try a fractional adjustment to nearest year
diff_yrs  = (mean(rmtime) - datenum('2010/08/01','yyyy/mm/dd'))/365;
iiyr      = find(n2o.annyrs == uyr);
frac_n2o  = (n2o.annmean(iiyr) - n2o.annmean(10))/n2o.annmean(10);
n2o.res  = (1+frac_n2o)*n2o.refprof;
%}

% Scale the reference profile with updated surface value
n2o.scale = n2o.upd*1E-3/n2o.refprofs(1,iiprf);
n2o.newprof = n2o.scale*n2o.refprofs(:,iiprf);

% reverse ordering of pressure (TOA to SFC)
n2o.press    = n2o.refplevs(end:-1:1,iiprf);
n2o.newprof  = n2o.newprof(end:-1:1);


% Interpolate to the number of ECMWF levels (60,91).
clear gas_4;
for i = 1:nprofs
  gas_4(:,i) = interp1(n2o.press, n2o.newprof, prof.plevs(:,i),...
               'pchip',n2o.newprof(1));
end

% update head and prof
head.ngas  = head.ngas + 1;
head.glist = [head.glist; 4];    % N2O gas4
head.gunit = [head.gunit; 10];   % N2O ppmv (~0.300)

prof.gas_4 = gas_4;




%{
% !!!! for stand-alone testing purposes only !!!!
% Pass through klayers

klayers_exec  = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';

% Save file and copy raw rtp data.
[sID, sTempPath] = genscratchpath();
fn_rtp1 = fullfile(sTempPath, ['airs_' sID '_1.rtp']);
fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);

rtpwrite(fn_rtp1,head,hattr,prof,pattr)

klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
               '/home/chepplew/logs/klayers/klout.txt'];
% Now run klayers
unix(klayers_run);

[hd2,ha2,pd2,pa2] = rtpread(fn_rtp2);

if(fn_rtp1) clear(fn_rtp1); end
if(fn_rtp2) clear(fn_rtp2); end
clear sd_* opts nprofs hd2 ha2 pd2 pa2 ch4 

%}


%{
% ============ not used for current N2O method ==================
clear iilat;
for i=1:length(sac.lat)-1
  iilat{i} = find(prof.rlat >= sac.lat(i) & prof.rlat < sac.lat(i+1) );
end

% figure;hold on; for i=1:44 plot(prof.rlat(iilat{i}),'.');end

[X,Y] = ndgrid(sac.lon, sac.lat);
iX = flipud(X); iY = flipud(Y);

% 60 x lon, 45 x lat, 34 x lev, 8 x time
clear F
for i = 1:size(n2o.tot_tmn,3)
  %%F.n2o(i).ig = griddedInterpolant(iX,iY,flipud(single(sd.tot_mn(:,:,i))),'linear');
  %%F.n2o(i).ig = griddedInterpolant(Y',X',flipud(squeeze(sd.tot_mn(:,:,i))),'linear');
  F.n2o(i).ig = griddedInterpolant(X,Y,(squeeze(n2o.tot_tmn(:,:,i))),'linear');
  %F.n2o(i).ig = griddedInterpolant(X,Y,(squeeze(sd.tot_mn(:,:,i))),'nearest');
end

% Assume rtp lat/lon are +-180??  Need to be 0-360 for interpolation
% loop over rlat,rlon
clear n2o.res;
for isp = 1:length(prof.rlat)
   rlat = prof.rlat(isp);
   rlon = prof.rlon(isp);
   %rlat(rlat<0) = rlat(rlat<0) + 90;
   %rlon(rlon<0) = rlon(rlon<0) + 360;

   for ilv = 1:n2o.nlevs
     n2o.res(ilv,isp)  = F.n2o(ilv).ig(rlon, rlat);
   end
end
   

 simplemap(prof.rlat, prof.rlon, n2o.res(2,:), 0.2,'lat',[0 40], 'lon',[-180 -130])
 simplemap(prof.rlat, prof.rlon, n2o.res(20,:),0.2,'lat',[0 40], 'lon',[-180 -130])

plot(squeeze(n2o.tot_tmn(4,27,:)),squeeze(sac.pressure(4,27,:,4)),'.-')
  hold on;plot(squeeze(n2o.tot_tmn(4,32,:)),squeeze(sac.pressure(4,32,:,4)),'.-')
  set(gca,'YScale','log');set(gca,'YDir','reverse');grid on;ylim([0.05 1100])
  plot(n2o.res(:,923),   squeeze(sac.pressure(4,32,:,4)),'c.-')
  plot(n2o.res(:,10046), squeeze(sac.pressure(4,32,:,4)),'m.-')

 junk = permute(n2o.tot_tmn(:,:,2),[2 1]);
  [uuu vvv] = ndgrid(sac.lat, sac.lon);
 simplemap(uuu, vvv, junk, 2.0)


% Load up most appropriate standard atmosphere to tack on upper levels


% match region and condition some variables
iiaa = find(sac.lat > min(prof.rlat) & sac.lat < max(prof.rlat));
iibb = find(sac.lon > min(prof.rlon) & sac.lon < max(prof.rlon));
sd_n2o_mn  = squeeze(nanmean(n2o.tot_tmn(iibb,iiaa,:),[1 2]));
sd_n2o_sd  = squeeze(nanstd(n2o.tot_tmn(iibb,iiaa,:),0,[1 2]));
sd_prs_mn  = squeeze(nanmean(sac.pressure(iibb,iiaa,1:end-1),[1 2]));
n2o.res_mn = squeeze(nanmean(n2o.res,2));
n2o.res_sd = squeeze(nanstd(n2o.res,0,2));

rlat_mn    = nanmean(prof.rlat);
%xpress_tmn = nanmean(sac.pressure,4);
sac_press_smn = squeeze(nanmean(sac.pressure,[1 2 4]));

opts = struct;
opts.latitude = rlat_mn;
opts.year     = uyr;
opts.month    = umn;

atm = load_standard_atmos(opts);

% splice top part of std onto ERSL profile
iipp = find( atm.PRE(:) <= min(nanmean(sac.pressure(:,:,1:end-1),[1 2])) );

ctop     = repmat(1E3*atm.N2O(iipp), 1, nprofs);
ptop     = repmat(atm.PRE(iipp), 1, nprofs); 
res2     = n2o.res;
n2o.res2 = [res2; ctop];
prs2     = repmat(sac_press_smn,1,nprofs);
prs2     = [prs2; ptop];


%hold on; plot(res2(:,923), prs2(:,923),'b.-')
%}


