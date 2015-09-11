addpath /home/sergio/MATLABCODE/PLOTTER

dir0 = '/asl/data/rtprod_cris_0/2012/02/13/';
thedir = dir([dir0 'cris_rdr60_allfov.2012.02.13*.rtp']);

all_lat = [];
all_lon = [];
all_solzen = [];

for ii = 1 : length(thedir)
  fname = [dir0 thedir(ii).name];
  fprintf(1,'fle %3i out of %3i %s \n',ii,length(thedir),fname);
  [h,ha,p,pa] = rtpread(fname);
  mean_solzen(ii) = nanmean(p.solzen);
  std_solzen(ii)  = nanstd(p.solzen);

  dadate = thedir(ii).name(19:28);
  ystr = dadate(1:4); mstr = dadate(6:7); dstr = dadate(9:10);
  tempdir = ['OUTPUT/UNIFORM_CLEAR/' ystr '/' mstr '/' dstr '/'];
  zname  = thedir(ii).name(1:end-4);  
  SUMOUT = [tempdir '/' zname 'out.mat'];

  loader = ['load ' SUMOUT];
  eval(loader)
  summary;

  figure(1); scatter_coast(summary.rlon,summary.rlat,20,summary.cleartest); ax = axis;
  figure(2); woo = find(summary.reason == 1);
  if length(woo) >= 3
    scatter_coast(summary.rlon(woo),summary.rlat(woo),20,summary.cleartest(woo))
    axis(ax);
    all_lat = [all_lat summary.rlat(woo)];
    all_lon = [all_lon summary.rlon(woo)];
    all_solzen = [all_solzen summary.solzen(woo)];        
  end
  fprintf(1,'found %4i out of %4i clear or roughly %8.6f percent \n',length(woo),length(summary.rlat),length(woo)/length(summary.rlat)*100)
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

figure(1); axis([-180 +180 -90 +90]);
figure(2); axis([-180 +180 -90 +90]);
figure(3); axis([-180 +180 -90 +90]);
figure(4); axis([-180 +180 -90 +90]);