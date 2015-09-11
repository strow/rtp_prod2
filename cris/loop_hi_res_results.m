addpath /home/sergio/MATLABCODE/PLOTTER
addpath /home/sergio/MATLABCODE/PLOTTER/

dir0 = '/asl/data/rtp_cris/2015/02/18/';
thedir = dir([dir0 'rtp_d20150218*.rtp']);

all_lat = [];
all_lon = [];
all_solzen = [];

random_lat = [];
random_lon = [];
random_solzen = [];

sergio_random_lat = [];
sergio_random_lon = [];
sergio_random_solzen = [];

for ii = 1 : length(thedir)
  fname = [dir0 thedir(ii).name];
  fprintf(1,'file %3i out of %3i %s \n',ii,length(thedir),fname);
  [h,ha,p,pa] = rtpread(fname);
  mean_solzen(ii) = nanmean(p.solzen);
  std_solzen(ii)  = nanstd(p.solzen);

  [keep,keep_ind] = hha_lat_subsample_equal_area2_cris_hires(h,p);
  sergio_random_lat    = [sergio_random_lat p.rlat(keep_ind)];
  sergio_random_lon    = [sergio_random_lon p.rlon(keep_ind)];
  sergio_random_solzen = [sergio_random_solzen p.solzen(keep_ind)];    

  dadate = thedir(ii).name(06:13);
  ystr = dadate(1:4); mstr = dadate(5:6); dstr = dadate(7:8);
  tempdir = ['OUTPUT/UNIFORM_CLEAR_HI/' ystr '/' mstr '/' dstr '/'];
  zname  = thedir(ii).name(1:end-4);  
  SUMOUT = [tempdir '/' zname 'out.mat'];

  loader = ['load ' SUMOUT];
  eval(loader)
  summary;

  figure(1); scatter_coast(summary.rlon,summary.rlat,20,summary.cleartest); ax = axis;

  woo = find(summary.reason == 1);
  if length(woo) >= 3
    figure(2); scatter_coast(summary.rlon(woo),summary.rlat(woo),20,summary.cleartest(woo)); title('uniform clear')
    axis(ax);
    all_lat = [all_lat summary.rlat(woo)];
    all_lon = [all_lon summary.rlon(woo)];
    all_solzen = [all_solzen summary.solzen(woo)];        
  end
  fprintf(1,'found %4i out of %4i clear or roughly %8.6f percent \n',length(woo),length(summary.rlat),length(woo)/length(summary.rlat)*100)

  woo = find(summary.reason == 8);
  if length(woo) >= 3
    figure(3); scatter_coast(summary.rlon(woo),summary.rlat(woo),20,summary.cleartest(woo)); title('random')
    axis(ax);
    random_lat = [random_lat summary.rlat(woo)];
    random_lon = [random_lon summary.rlon(woo)];
    random_solzen = [random_solzen summary.solzen(woo)];        
  end
  fprintf(1,'found %4i out of %4i random or roughly %8.6f percent \n',length(woo),length(summary.rlat),length(woo)/length(summary.rlat)*100)

  dlat = -90 : 1 : +90;
  boo = find(abs(dlat) < 10);   
  figure(4);
  junk = hist(random_lat,dlat);        junk = nanmean(junk(boo));
  sunk = hist(sergio_random_lat,dlat); sunk = nanmean(sunk(boo));  
  plot(dlat,hist(random_lat,dlat),'b',dlat,cos(dlat*pi/180)*junk,'b--',dlat,hist(sergio_random_lat,dlat),'r',dlat,cos(dlat*pi/180)*sunk,'r--'); 

  disp('ret to continue'); pause(1)
  pause(0.1);
  
end

figure(1); clf;
  iix = find(all_solzen > 90); scatter_coast(all_lon(iix),all_lat(iix),20,all_solzen(iix)); title('cris night');
figure(2); clf;
  iix = find(all_solzen < 90); scatter_coast(all_lon(iix),all_lat(iix),20,all_solzen(iix)); title('cris day');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath /asl/matlib/h4tools
addpath /asl/matlib/rtptools

daysINmonth = [31 28 31 30 31 30 31 31 30 31 30 31];
if mod(str2num(ystr),4) == 0
  daysINmonth(2) = 29;
end
daysSOfar = sum(daysINmonth(1:str2num(mstr)-1)) + str2num(dstr);
airsfile = ['/asl/data/rtp_airxbcal_v5/' ystr '/clear/era_airxbcal_day' num2str(daysSOfar,'%03d') '_clear.rtp'];
[hairs,ha,pairs,pa] = rtpread(airsfile);

figure(3); clf;
  iix = find(pairs.solzen > 90); scatter_coast(pairs.rlon(iix),pairs.rlat(iix),20,pairs.solzen(iix)); title('airs night');
figure(4); clf;
  iix = find(pairs.solzen < 90); scatter_coast(pairs.rlon(iix),pairs.rlat(iix),20,pairs.solzen(iix)); title('airs day');

figure(1); axis([-180 +180 -90 +90]); colormap(jet)
figure(2); axis([-180 +180 -90 +90]); colormap(jet)
figure(3); axis([-180 +180 -90 +90]); colormap(jet)
figure(4); axis([-180 +180 -90 +90]); colormap(jet)

figure(5); clf
  dlat = -90 : 1 : +90;
  boo = find(abs(dlat) < 10);   
  junk = hist(random_lat,dlat);        junk = nanmean(junk(boo));
  sunk = hist(sergio_random_lat,dlat); sunk = nanmean(sunk(boo));  
  plot(dlat,hist(random_lat,dlat),'b',dlat,cos(dlat*pi/180)*junk,'b--',...
       dlat,hist(sergio_random_lat,dlat),'r',dlat,cos(dlat*pi/180)*sunk,'r--','linewidth',2); 
fprintf(1,' scott/sergio had %6i/%6i random latitudes \n',length(random_lat),length(sergio_random_lat))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load /asl/s1/strow/AIRS_V6/Airxbcal/SNDR.AQUA.AIRS.20150218.D1.CalSub.xxixxxx.AIN.CalSub_Summary.standard.v11_0_0.S.150610184106.mat
addpath /home/sergio/MATLABCODE
fAIRS = '/asl/s1/strow/AIRS_V6/Airxbcal/SNDR.AQUA.AIRS.20150218.D1.RTP3.xxixxxx.AIN.CalSub_Random.standard.v11_0_0.S.150610184106.nc';
airs = read_netcdf_lls(fAIRS);

figure(6)
dlat = -90 : 1: +90;
plot(dlat,hist(airs.IRInst.lat,dlat),dlat,cos(pi/180*dlat)*max(hist(airs.IRInst.lat,dlat)))
fprintf(1,' V6 file had %6i latitudes \n',length(airs.IRInst.lat))

fact = 0.25;
fact = 0.33;
fact = 0.40;
figure(7); clf
  dlat = -90 : 1 : +90;
  boo = find(abs(dlat) < 10);   
  junk = hist(random_lat,dlat);        junk = nanmean(junk(boo));
  sunk = hist(sergio_random_lat,dlat); sunk = nanmean(sunk(boo));
  aunk = hist(airs.IRInst.lat,dlat);   aunk = nanmean(aunk(boo));    
  plot(dlat,hist(random_lat,dlat),'b',dlat,cos(dlat*pi/180)*junk,'b--',...
       dlat,hist(sergio_random_lat,dlat),'r',dlat,cos(dlat*pi/180)*sunk,'r--',...
       dlat,hist(airs.IRInst.lat,dlat)*fact,'k',dlat,cos(pi/180*dlat)*aunk*fact,'k--','linewidth',2); 
fprintf(1,' scott/sergio had %6i/%6i random latitudes \n',length(random_lat),length(sergio_random_lat))
grid

fprintf(1,'AIRS v6 : Scott : Sergio count = %6i %6i %6i \n',[length(airs.IRInst.lat) length(random_lat),length(sergio_random_lat)])
disp('see /asl/rtp_prod/cris/uniform/site_dcc_random.m : randadjust = 0.1;')
disp('see /home/sergio/MATLABCODE/PLOTTER/hha_lat_subsample_equal_area2_cris_hires.m : factor of 1/6, but limit satzen to 1.75 deg')
