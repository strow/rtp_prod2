rtpfile = '/asl/rtp/airs_l1c_v6/allfov/2018/008/allfov_ecmwf_airicrad_day_2018008_115.rtp';
[h,ha,p,pa] = rtpread(rtpfile);

fprintf(1, '> normal rtp order\n')
ptest.rtime = p.rtime;
ptest.rlat = p.rlat;
ptest.rlon = p.rlon;
ptest.salti = p.salti;
ptest.landfrac = p.landfrac;
ptest.satzen = p.satzen;
ptest.solzen = p.solzen;
ptest.stemp = p.stemp;
ptest.wspeed = p.wspeed;
[pt,pat] = rtp_add_emis(ptest,pa);

fprintf(1, '> sergio''s rtp order\n');
pttest.rtime = p.rtime';
pttest.rlat = p.rlat';
pttest.rlon = p.rlon';
pttest.salti = p.salti';
pttest.landfrac = p.landfrac';
pttest.satzen = p.satzen';
pttest.solzen = p.solzen';
pttest.stemp = p.stemp';
pttest.wspeed = p.wspeed';
[ptt,patt] = rtp_add_emis(pttest,pa);

