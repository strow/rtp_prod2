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

%iType = input('Enter (1) Paul 2012/02/13  (2) Sergio lo res 2014/12/03 (3) Steve hi res 2015/02/18 (4) Breno 2014/03/01 JUNK: ');
iType = 1;   % made by Paul 
iType = 2;   % made by Sergio
iType = 3;   % made by Steve

if iType == 1
  dir0 = '/asl/data/rtprod_cris_0/2012/02/13/';
  thedir = dir([dir0 'cris_rdr60_allfov.2012.02.13*.rtp']);
elseif iType == 2
  dir0 = '/asl/s1/sergio/CRIS_CCAST/sdr60_lr/2014/338/';
  thedir = dir([dir0 'SCRIS_npp_d20141204*.rtp']);
elseif iType == 3
  dir0 = '/asl/data/rtp_cris/2015/02/18/';
  thedir = dir([dir0 'rtp_d20150218*.rtp']);
elseif iType == 4
  dir0 = '/asl/data/rtprod_cris/2014/03/03/';
  thedir = dir([dir0 'cris_ccast_sdr60.ecmwf.umw.2014.03.03.*-M1.9l.rtp']);
end


if iType == 2
  %% there are some bad files
  for ii = 1 : length(thedir)
    if mod(ii,20) == 0
      fprintf(1,'%4i out of %4i \n',ii,length(thedir))
    end
    fname = [dir0 thedir(ii).name];
    fsize = [thedir(ii).bytes];
    if fsize < 236793134-1000
      iaGood(ii) = -1;
    else
      iaGood(ii) = +1;
      %[h,ha,p,pa] = rtpread(fname);        
    end
  end

   aha = find(iaGood > 0);
   thedirx = struct;
   for ii = 1 : length(aha)
     thedirx(ii).name = thedir(aha(ii)).name;
     thedirx(ii).date = thedir(aha(ii)).date;
     thedirx(ii).bytes = thedir(aha(ii)).bytes;
     thedirx(ii).isdir = thedir(aha(ii)).isdir;
     thedirx(ii).datenum = thedir(aha(ii)).datenum;
   end
   thedir0 = thedir;
   thedir = thedirx;
end

the_comparisons = struct;
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

  %%%%%%%%%%%%%%%
  %% because Scott used to write temporary files, including the one just one read
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
  %%%%%%%%%%%%%%%

  rtpwrite(RTPIN,h,ha,p,pa);
  if iType == 1
    fx = uniform_clear_template_fix(RTPIN,RTPOUT,SUMOUT);
  elseif iType == 2
    %%%% >>>>>>>>>>>>>>>> guts of testing lo res  
    fx = uniform_clear_template(RTPIN,RTPOUT,SUMOUT);
    [hx,hax,pold,pax] = rtpread(RTPOUT);

    disp('  ')
    disp(' A NOT DONE as this is ONLY for hi res')

    %pnew = uniform_clear_template_hires_HP(h,ha,p,pa);        %% my newer stuff, where I have updated "random", and no output file
                                                              %% use this with Steve's exisitng rtp CRIS HiRes which already have rcalc
    disp('  ')
    disp(' B ')
    pnewer = uniform_clear_template_lowANDhires_HP(h,ha,p,pa); %% super (if it works)

    disp('  ')
    disp(' C ')
    px = p;
    px = rmfield(p,'rcalc'); hx = h; hx.pfields = 5; 
    pnewest = uniform_clear_template_lowANDhires_HP(hx,ha,px,pa); %% super (if it works)

    disp(' B-C ')
    if length(pnewer.rlat) == length(pnewest.rlat)
      sum(pnewer.rlat-pnewest.rlat)
    else
      disp('WHOA different B,C')
    end

    woo = find(pold.iudef(1,:) == 1 | pold.iudef(1,:) == 2 | pold.iudef(1,:) == 4 | pold.iudef(1,:) == 8);
      the_comparisons(ii).type0lat = pold.rlat(woo);
      the_comparisons(ii).type0lon = pold.rlon(woo);
      the_comparisons(ii).type0    = pold.iudef(1,woo);
      the_comparisons(ii).type0sol = pold.solzen(woo);
      the_comparisons(ii).type0lf  = pold.landfrac(woo);            
      the_comparisons(ii).type0rad = pold.robs1(499,woo);  %% rad961   id = 503 for hires
    %{
    woo = find(pnew.iudef(1,:) == 1 | pnew.iudef(1,:) == 2 | pnew.iudef(1,:) == 4 | pnew.iudef(1,:) == 8);
      the_comparisons(ii).typeAlat = pnew.rlat(woo);
      the_comparisons(ii).typeAlon = pnew.rlon(woo);
      the_comparisons(ii).typeA    = pnew.iudef(1,woo);
      the_comparisons(ii).typeAsol = pnew.solzen(woo);
      the_comparisons(ii).typeAlf  = pnew.landfrac(woo);            
      the_comparisons(ii).typeArad = pnew.robs1(499,woo);  %% rad961   id = 503 for hires
    %}
    woo = find(pnewer.iudef(1,:) == 1 | pnewer.iudef(1,:) == 2 | pnewer.iudef(1,:) == 4 | pnewer.iudef(1,:) == 8);
      the_comparisons(ii).typeBlat = pnewer.rlat(woo);
      the_comparisons(ii).typeBlon = pnewer.rlon(woo);
      the_comparisons(ii).typeB    = pnewer.iudef(1,woo);
      the_comparisons(ii).typeBsol = pnewer.solzen(woo);
      the_comparisons(ii).typeBlf  = pnewer.landfrac(woo);            
      the_comparisons(ii).typeBrad = pnewer.robs1(499,woo);  %% rad961   id = 503 for hires
    woo = find(pnewest.iudef(1,:) == 1 | pnewest.iudef(1,:) == 2 | pnewest.iudef(1,:) == 4 | pnewest.iudef(1,:) == 8);
      the_comparisons(ii).typeClat = pnewest.rlat(woo);
      the_comparisons(ii).typeClon = pnewest.rlon(woo);
      the_comparisons(ii).typeC    = pnewest.iudef(1,woo);
      the_comparisons(ii).typeCsol = pnewest.solzen(woo);
      the_comparisons(ii).typeClf  = pnewest.landfrac(woo);            
      the_comparisons(ii).typeCrad = pnewest.robs1(499,woo);  %% rad961   id = 503 for hires
      
    figure(1); clf; oo = find(pold.iudef(1,:) == 1); scatter_coast(pold.rlon(oo),pold.rlat(oo),30,pold.stemp(oo)); title('ORIG')
    figure(3); clf; oo = find(pnewer.iudef(1,:) == 1); scatter_coast(pnewer.rlon(oo),pnewer.rlat(oo),30,pnewer.stemp(oo)); title('B')
    figure(4); clf; oo = find(pnewest.iudef(1,:) == 1); scatter_coast(pnewest.rlon(oo),pnewest.rlat(oo),30,pnewest.stemp(oo)); title('C')
    figure(1); cx = caxis; colormap(jet)
    %figure(2); caxis(cx); colormap(jet)
    figure(3); caxis(cx); colormap(jet)
    figure(4); caxis(cx); colormap(jet)    
    pause(5);
    
  elseif iType == 3
    %%%% >>>>>>>>>>>>>>>> guts of testing hi res
    fx = uniform_clear_template_hires(RTPIN,RTPOUT,SUMOUT);   %% totally based on Scott, which writes 2-3 temp files
    [hx,hax,pold,pax] = rtpread(RTPOUT);

    disp('  ')
    disp(' A ')

    pnew = uniform_clear_template_hires_HP(h,ha,p,pa);        %% my newer stuff, where I have updated "random", and no output file
                                                              %% use this with Steve's exisitng rtp CRIS HiRes which already have rcalc
    disp('  ')
    disp(' B ')
    pnewer = uniform_clear_template_lowANDhires_HP(h,ha,p,pa); %% super (if it works)

    disp('  ')
    disp(' C ')
    px = p;
    px = rmfield(p,'rcalc'); hx = h; hx.pfields = 5; 
    pnewest = uniform_clear_template_lowANDhires_HP(hx,ha,px,pa); %% super (if it works)

    disp(' B-C ')
    if length(pnewer.rlat) == length(pnewest.rlat)
      sum(pnewer.rlat-pnewest.rlat)
    else
      disp('WHOA different B,C')
    end    

    woo = find(pold.iudef(1,:) == 1 | pold.iudef(1,:) == 2 | pold.iudef(1,:) == 4 | pold.iudef(1,:) == 8);
      the_comparisons(ii).type0lat = pold.rlat(woo);
      the_comparisons(ii).type0lon = pold.rlon(woo);
      the_comparisons(ii).type0    = pold.iudef(1,woo);
      the_comparisons(ii).type0sol = pold.solzen(woo);
      the_comparisons(ii).type0lf  = pold.landfrac(woo);            
      the_comparisons(ii).type0rad = pold.robs1(503,woo);  %% rad961   id = 499 for lores
    woo = find(pnew.iudef(1,:) == 1 | pnew.iudef(1,:) == 2 | pnew.iudef(1,:) == 4 | pnew.iudef(1,:) == 8);
      the_comparisons(ii).typeAlat = pnew.rlat(woo);
      the_comparisons(ii).typeAlon = pnew.rlon(woo);
      the_comparisons(ii).typeA    = pnew.iudef(1,woo);
      the_comparisons(ii).typeAsol = pnew.solzen(woo);
      the_comparisons(ii).typeAlf  = pnew.landfrac(woo);            
      the_comparisons(ii).typeArad = pnew.robs1(503,woo);  %% rad961   id = 499 for lores
    woo = find(pnewer.iudef(1,:) == 1 | pnewer.iudef(1,:) == 2 | pnewer.iudef(1,:) == 4 | pnewer.iudef(1,:) == 8);
      the_comparisons(ii).typeBlat = pnewer.rlat(woo);
      the_comparisons(ii).typeBlon = pnewer.rlon(woo);
      the_comparisons(ii).typeB    = pnewer.iudef(1,woo);
      the_comparisons(ii).typeBsol = pnewer.solzen(woo);
      the_comparisons(ii).typeBlf  = pnewer.landfrac(woo);            
      the_comparisons(ii).typeBrad = pnewer.robs1(503,woo);  %% rad961   id = 499 for lores
    woo = find(pnewest.iudef(1,:) == 1 | pnewest.iudef(1,:) == 2 | pnewest.iudef(1,:) == 4 | pnewest.iudef(1,:) == 8);
      the_comparisons(ii).typeClat = pnewest.rlat(woo);
      the_comparisons(ii).typeClon = pnewest.rlon(woo);
      the_comparisons(ii).typeC    = pnewest.iudef(1,woo);
      the_comparisons(ii).typeCsol = pnewest.solzen(woo);
      the_comparisons(ii).typeClf  = pnewest.landfrac(woo);            
      the_comparisons(ii).typeCrad = pnewest.robs1(503,woo);  %% rad961   id = 499 for lores

    figure(1); clf; oo = find(pold.iudef(1,:) == 1); scatter_coast(pold.rlon(oo),pold.rlat(oo),30,pold.stemp(oo)); title('ORIG')
    figure(3); clf; oo = find(pnew.iudef(1,:) == 1); scatter_coast(pnew.rlon(oo),pnew.rlat(oo),30,pnew.stemp(oo)); title('A')    
    figure(3); clf; oo = find(pnewer.iudef(1,:) == 1); scatter_coast(pnewer.rlon(oo),pnewer.rlat(oo),30,pnewer.stemp(oo)); title('B')
    figure(4); clf; oo = find(pnewest.iudef(1,:) == 1); scatter_coast(pnewest.rlon(oo),pnewest.rlat(oo),30,pnewest.stemp(oo)); title('C')
    figure(1); cx = caxis; colormap(jet)
    figure(2); caxis(cx); colormap(jet)
    figure(3); caxis(cx); colormap(jet)
    figure(4); caxis(cx); colormap(jet)    
    pause(5);    
    
    %%% pold and out better be the same!
    disp('  ')
    fprintf(1,'   checking structures new and old : length(p) = %5i %5i \n',length(pnew.stemp),length(pold.stemp))

    iFind = 1;  woo_new = find(pnew.iudef(1,:) == iFind); woo_old = find(pold.iudef(1,:) == iFind);
    if length(woo_new) ~= length(woo_old)
      fprintf(1,'    oops : number of uniform clear are different %4i %4i \n',length(woo_new),length(woo_old))
      setdiff(sort(pnew.rlat(woo_new)),sort(pold.rlat(woo_old)))
      setdiff(sort(pnew.rlon(woo_new)),sort(pold.rlon(woo_old)))
    else
      [sum(pnew.rlon(woo_new)-pold.rlon(woo_old)) sum(pnew.rlat(woo_new)-pold.rlat(woo_old)) sum(pnew.iudef(1,woo_new)-pold.iudef(1,woo_old))]
    end

    iFind = 2;  woo_new = find(pnew.iudef(1,:) == iFind); woo_old = find(pold.iudef(1,:) == iFind);
    if length(woo_new) ~= length(woo_old)
      fprintf(1,'    oops : number of site are different %4i %4i \n',length(woo_new),length(woo_old))
    else
      [sum(pnew.rlon(woo_new)-pold.rlon(woo_old)) sum(pnew.rlat(woo_new)-pold.rlat(woo_old)) sum(pnew.iudef(1,woo_new)-pold.iudef(1,woo_old))]
    end

    iFind = 4;  woo_new = find(pnew.iudef(1,:) == iFind); woo_old = find(pold.iudef(1,:) == iFind);
    if length(woo_new) ~= length(woo_old)
      fprintf(1,'    oops : number of DCC are different %4i %4i \n',length(woo_new),length(woo_old))        
    else
      [sum(pnew.rlon(woo_new)-pold.rlon(woo_old)) sum(pnew.rlat(woo_new)-pold.rlat(woo_old)) sum(pnew.iudef(1,woo_new)-pold.iudef(1,woo_old))]
    end

    iFind = 8;  woo_new = find(pnew.iudef(1,:) == iFind); woo_old = find(pold.iudef(1,:) == iFind);
    if length(woo_new) ~= length(woo_old)
      fprintf(1,'    oops : number of random are different %4i %4i \n',length(woo_new),length(woo_old))        
    else
      [sum(pnew.rlon(woo_new)-pold.rlon(woo_old)) sum(pnew.rlat(woo_new)-pold.rlat(woo_old)) sum(pnew.iudef(1,woo_new)-pold.iudef(1,woo_old))]
    end

    %%%% >>>>>>>>>>>>>>>> guts of testing    
  end
  
  rmer = ['!/bin/rm ' RTPIN]; eval(rmer);
  
  %ix = find(h.vchan >= 1231,1);
  %figure(3); scatter_coast(p.rlon,p.rlat,20,rad2bt(h.vchan(ix),p.robs1(ix,:))); title('BT1231 obs')

  loader = ['load ' SUMOUT];
  eval(loader)
  summary;

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

  if mod(ii,20) == 0
    comment = 'see loop_test_scott_code_HP.m';
    saver = ['save the_comparisons_iType' num2str(iType) '.mat the_comparisons comment'];
    eval(saver);
  end
  
  pause(0.1);
end

comment = 'see loop_test_scott_code_HP.m';
saver = ['save the_comparisons_iType' num2str(iType) '.mat the_comparisons comment'];
eval(saver);
  
