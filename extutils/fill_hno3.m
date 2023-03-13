% function [head,prof,pattr] = fill_hno3(head,prof,pattr)

%
% load HNO3 (gas_12) profile given location and date
%
%



addpath /asl/matlib/time
addpath /home/chepplew/projects/airs
addpath /home/chepplew/myLib/matlib

def = struct;
% Default std. atm gas:12 :HNO3 (ppmv)
 def.hno3 = ...
 [5.00E-05,  5.96E-05,  6.93E-05,  7.91E-05,  8.87E-05, ...
  9.75E-05,  1.11E-04,  1.26E-04,  1.39E-04,  1.53E-04, ...
  1.74E-04,  2.02E-04,  2.41E-04,  2.76E-04,  3.33E-04, ...
  4.52E-04,  7.37E-04,  1.31E-03,  2.11E-03,  3.17E-03, ...
  4.20E-03,  4.94E-03,  5.46E-03,  5.74E-03,  5.84E-03, ...
  5.61E-03,  4.82E-03,  3.74E-03,  2.59E-03,  1.64E-03, ...
  9.68E-04,  5.33E-04,  2.52E-04,  1.21E-04,  7.70E-05, ...
  5.55E-05,  4.45E-05,  3.84E-05,  3.49E-05,  3.27E-05, ...
  3.12E-05,  3.01E-05,  2.92E-05,  2.84E-05,  2.78E-05, ...
  2.73E-05,  2.68E-05,  2.64E-05,  2.60E-05,  2.57E-05];
%
% std. Pressure (mb)
def.press = ...
 [1.013E+03, 8.988E+02, 7.950E+02, 7.012E+02, 6.166E+02, ...
  5.405E+02, 4.722E+02, 4.111E+02, 3.565E+02, 3.080E+02, ...
  2.650E+02, 2.270E+02, 1.940E+02, 1.658E+02, 1.417E+02, ...
  1.211E+02, 1.035E+02, 8.850E+01, 7.565E+01, 6.467E+01, ...
  5.529E+01, 4.729E+01, 4.047E+01, 3.467E+01, 2.972E+01, ...
  2.549E+01, 1.743E+01, 1.197E+01, 8.010E+00, 5.746E+00, ...
  4.150E+00, 2.871E+00, 2.060E+00, 1.491E+00, 1.090E+00, ...
  7.978E-01, 4.250E-01, 2.190E-01, 1.090E-01, 5.220E-02, ...
  2.400E-02, 1.050E-02, 4.460E-03, 1.840E-03, 7.600E-04, ...
  3.200E-04, 1.450E-04, 7.100E-05, 4.010E-05, 2.540E-05];
%


% Location of MLS files
m.home = '/home/chepplew/data/MLS_HNO3/';

% Sample AIRS granule
hdf_fn='/asl/airs/l1c_v672/2019/018/AIRS.2019.01.18.001.L1C.AIRS_Rad.v6.7.2.0.G19360072949.hdf';

%[head,hattr,prof,pattr] = airs_l1c_to_rtp(hdf_fn,0);

% allocate memory for gas_12
prof.gas_12 = NaN(size(prof.plevs));


ename = '';  % This should be placed outside a rtp file loop

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

m.fname = [m.home 'MLS-Aura_L3MB-HNO3_v04-23-c01_' sprintf('%04d',uyr(1)) '.nc'];

if(~exist(m.fname))
  error('no available MLS HNO3 file');
  return;
end

mdata   = load_one_mls_lev3_hno3(uyr);
% use field 2: PressureZM  [45 lat x 37 lev x 12 month]
m.plevs = mdata(2).lev;
junk    = mdata(2).value;
m.hno3  = squeeze(junk(:,:,umn));
% Get MLS zonal band boundaries:
junk    = mdata(2).lat_bnds;
m.latB  = [junk(1,1:end) junk(2,end)];

% Get the appropriate std. atmosphere to initialize the profile:
%fnstd = '/asl/packages/klayersV205/Data/glatm.dat';

clear iilat;
for i=1:length(m.latB)-1
  iilat{i} = find(prof.rlat >= m.latB(i) & prof.rlat < m.latB(i+1) );
end

%{
% plot check
figure;hold on;grid on;
  for i=1:length(m.latB)-1
    if( ~isempty(iilat{i}) )
      plot(prof.rlat(iilat{i}),'.');
    end
  end
nanmean(prof.rlat(iilat{i}))
%}

% Get the MLS profile for each zonal band that is present
iwnt = [];
for i=1:length(iilat)
  if( ~isempty(iilat{i}) )
    iwnt = [iwnt i];
  end
end

% valid MLS height range
m.pmin = 1.5;   % hPa
m.pmax = 215;   % hPa
m.iipr = find(m.plevs >= m.pmin & m.plevs <= m.pmax);
 iipr  = find(def.press < m.pmin,1);
 iipr  = find(def.press > m.pmax);

% For interpolation to ECM plevs use average pressure grid.
plevs_mn = nanmean(prof.plevs,2);
 
% For each zonal band present process the HNO3 profiles
for i = iwnt
  m.prf = 1E6* squeeze(m.hno3(i,:));     % ! 1E6* convert to ppmv

  % splice MLS profile into std.atm profile
  xprf   = [def.hno3(1:12) m.prf(m.iipr) def.hno3(33:end)];
  xpress = [def.press(1:12) m.plevs(m.iipr)' def.press(33:end)];

  % Interpolate back onto original std.atm pressure grid
  %inprf = interp1(xpress, xprf, def.press,'spline');

  % Interpolate onto ecmwf 60 pressure grid
  inprf = interp1(xpress, xprf, plevs_mn,'spline');

  % assign this profile to the FOVs in this lat band
  prof.gas_12(:,iilat{i}) = inprf.*ones(60,length(iilat{i}));

end
%{
% plot check
figure; hold on; grid on; ylim([0.01 1100])
  set(gca,'YDir','reverse');set(gca,'YScale','log')
  plot(def.hno3, def.press,'.-');
  plot(m.prf, m.plevs,'.-');
  %plot(inprf, def.press,'.-')
  plot(inprf, plevs_mn,'.-')

  simplemap(prof.rlat, prof.rlon, prof.gas_12(19,:))

%}

% Update head
head.glist = [head.glist; 12];
head.gunit = [head.gunit; 10];
head.ngas  = 3;

% Pass this rtp thro klayers
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



