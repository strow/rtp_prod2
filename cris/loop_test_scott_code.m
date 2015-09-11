addpath /asl/matlab2012/cris/clear
addpath /asl/matlab2012/cris/uniform
addpath /asl/matlib/h4tools
addpath /asl/matlib/rtptools
addpath /asl/matlib/aslutil
addpath /asl/matlib/science/
addpath /asl/matlab2012/cris/unapod
addpath /home/sergio/MATLABCODE/PLOTTER

%% see /home/sergio/MATLABCODE/CRIS/CLEAR_UNIFORM
%% see /home/sergio/MATLABCODE/CRIS/CLEAR_UNIFORM
%% see /home/sergio/MATLABCODE/CRIS/CLEAR_UNIFORM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% this is all from /home/sergio/MATLABCODE/CRIS/CLEAR_UNIFORM

%% OUTPUT -> /asl/s1/sergio/CRIS_CCAST

iType = 1;   % made by Paul 
iType = 2;   % made by Sergio

iType = input('Enter (1) Paul 2012/02/13  (2) Sergio lo res 2014/12/03 (3) Steve hi res 2015/02/18 (4) Breno 2014/03/01 JUNK: ');

if iType == 1
  dir0 = '/asl/data/rtprod_cris_0/2012/02/13/';
  thedir = dir([dir0 'cris_rdr60_allfov.2012.02.13*.rtp']);
elseif iType == 2
  dir0 = '/asl/s1/sergio/CRIS_CCAST/sdr60_lr/2014/338/';
  thedir = dir([dir0 'SCRIS_npp_d20141204*.rtp']);
elseif iType == 3
  dir0 = '/asl/s1/sergio/CRIS_CCAST/sdr60_hr/2014/338/';
  thedir = dir([dir0 'SDR_d20141204*.rtp']);
  dir0 = '/asl/data/rtp_cris/2015/02/18/';
  thedir = dir([dir0 'rtp_d20150218*.rtp']);
elseif iType == 4
  dir0 = '/asl/data/rtprod_cris/2014/03/03/';
  thedir = dir([dir0 'cris_ccast_sdr60.ecmwf.umw.2014.03.03.*-M1.9l.rtp']);
end

for ii = 1 : length(thedir)
  fname = [dir0 thedir(ii).name];
  fprintf(1,'file %3i out of %3i %s \n',ii,length(thedir),fname);
  
  [h,ha,p,pa] = rtpread(fname);
  if iType == 4
    [h,ha,p,pa] = rtpgrow(h,ha,p,pa);
  end

  figure(1); clf; plot(h.vchan,p.rcalc(:,1),'b',h.vchan,p.robs1(:,1),'r'); pause(0.1);
  if ~isfield(p,'findex')
    p.findex = ones(1,length(p.rlon),'int32');  
  end

  ix = find(h.vchan >= 1231,1);
  figure(2); clf; scatter_coast(p.rlon,p.rlat,20,rad2bt(h.vchan(ix),p.robs1(ix,:))); title('BT1231 OBS'); colormap(jet)
  figure(3); clf; scatter_coast(p.rlon,p.rlat,20,rad2bt(h.vchan(ix),p.robs1(ix,:))-rad2bt(h.vchan(ix),p.rcalc(ix,:)));
         title('BT1231 OBS-CAL'); colormap(jet)  

  if iType == 1
    dadate = thedir(ii).name(19:28);
    ystr = dadate(1:4); mstr = dadate(6:7); dstr = dadate(9:10);
  elseif iType == 2
    dadate = thedir(ii).name(12:19);    
    ystr = dadate(1:4); mstr = dadate(5:6); dstr = dadate(7:8);    
  elseif iType == 3
    dadate = thedir(ii).name(6:13);    
    ystr = dadate(1:4); mstr = dadate(5:6); dstr = dadate(7:8);    
  end

  if iType ~= 3
    tempdir = ['OUTPUT/UNIFORM_CLEAR/' ystr '/' mstr '/' dstr '/'];
  elseif iType == 3
    tempdir = ['OUTPUT/UNIFORM_CLEAR_HI/' ystr '/' mstr '/' dstr '/'];
  end
  if ~exist(tempdir)
    mker = ['!mkdir -p ' tempdir];
    eval(mker);
    fprintf(1,'made %s \n',tempdir);
  end

  zname  = thedir(ii).name(1:end-4);
  RTPIN  = [tempdir '/' thedir(ii).name];
  RTPOUT = [tempdir '/' zname 'out.rtp'];
  SUMOUT = [tempdir '/' zname 'out.mat'];

  rtpwrite(RTPIN,h,ha,p,pa);
  if iType == 1
    fx = uniform_clear_template_fix(RTPIN,RTPOUT,SUMOUT);
  elseif iType == 2 | iType == 4
    fx = uniform_clear_template(RTPIN,RTPOUT,SUMOUT);
  elseif iType == 3
    fx = uniform_clear_template_hires(RTPIN,RTPOUT,SUMOUT);
  end
  
  rmer = ['!/bin/rm ' RTPIN]; eval(rmer);
  
  %ix = find(h.vchan >= 1231,1);
  %figure(3); scatter_coast(p.rlon,p.rlat,20,rad2bt(h.vchan(ix),p.robs1(ix,:))); title('BT1231 obs')

  loader = ['load ' SUMOUT];
  eval(loader)
  summary

  figure(4); scatter_coast(summary.rlon,summary.rlat,20,summary.cleartest); ax = axis; title('CLEARTEST')

  woo = find(summary.reason == 1);
  fprintf(1,'found %4i out of %4i clear or roughly %8.6f percent \n',length(woo),length(summary.rlat),length(woo)/length(summary.rlat)*100)  
  if length(woo) >= 3
    figure(5); scatter_coast(summary.rlon(woo),summary.rlat(woo),20,summary.cleartest(woo)); title('UNIFORM CLEAR')
    axis(ax);
  end

  woo = find(summary.reason == 2);
  fprintf(1,'found %4i out of %4i site or roughly %8.6f percent \n',length(woo),length(summary.rlat),length(woo)/length(summary.rlat)*100)
  if length(woo) >= 3
    figure(6); scatter_coast(summary.rlon(woo),summary.rlat(woo),20,summary.cleartest(woo)); title('SITE')
    axis(ax);
  end
  
  woo = find(summary.reason == 4);
  fprintf(1,'found %4i out of %4i DCC or roughly %8.6f percent \n',length(woo),length(summary.rlat),length(woo)/length(summary.rlat)*100)  
  if length(woo) >= 3
    figure(7); scatter_coast(summary.rlon(woo),summary.rlat(woo),20,summary.cleartest(woo)); title('DCC')
    axis(ax);
  end
  
  woo = find(summary.reason == 8);      
  fprintf(1,'found %4i out of %4i random or roughly %8.6f percent \n',length(woo),length(summary.rlat),length(woo)/length(summary.rlat)*100)
  if length(woo) >= 3
    figure(8); scatter_coast(summary.rlon(woo),summary.rlat(woo),20,summary.cleartest(woo)); title('RANDOM')
    axis(ax);
  end

  woo = find(summary.reason == 16);      
  fprintf(1,'found %4i out of %4i coast or roughly %8.6f percent \n',length(woo),length(summary.rlat),length(woo)/length(summary.rlat)*100)
  %if length(woo) >= 3
  %  figure(7); scatter_coast(summary.rlon(woo),summary.rlat(woo),20,summary.cleartest(woo)); title('COAST')
  %  axis(ax);
  %end

  woo = find(summary.reason == 32);      
  fprintf(1,'found %4i out of %4i bad or roughly %8.6f percent \n',length(woo),length(summary.rlat),length(woo)/length(summary.rlat)*100)  
  %if length(woo) >= 3
  %  figure(7); scatter_coast(summary.rlon(woo),summary.rlat(woo),20,summary.cleartest(woo)); title('BAD')
  %  axis(ax);
  %end

  %disp('ret to continue'); pause
  
  pause(0.1);
  
end
