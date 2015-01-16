function [head hattr prof pattr] = sdr2rtp_h5(f)

  [prof pattr] = readsdr_rtp(f);

  % Sarta g4 channels that are not in Proxy data 
  ibad = [ 1306 1307 1312:1315 1320:1323 1328:1329];

  % Now change indices to g4 of SARTA
  robs = prof.robs1;
  nn = length(prof.rlat);
  prof.robs1 = zeros(1329,nn);
  prof.robs1(ibad,:) = -9999;
  % prof.robs1(si,:) = robs(pi,:);    % test and implement later
  prof.robs1(1:713,:)     = robs(3:715,:);
  prof.robs1(714:1146,:)  = robs(720:1152,:);
  prof.robs1(1147:1305,:) = robs(1157:1315,:);
  prof.robs1(1308:1309,:) = robs(1:2,:);
  prof.robs1(1310:1311,:) = robs(716:717,:);
  prof.robs1(1316:1317,:) = robs(718:719,:);
  prof.robs1(1318:1319,:) = robs(1153:1154,:);
  prof.robs1(1324:1325,:) = robs(1155:1156,:);
  prof.robs1(1326:1327,:) = robs(1316:1317,:);

  % Declare iudef
  if ~isfield(prof,'iudef')
    prof.iudef = zeros(10,length(prof.rtime));
  end

  % From g4 variant of CrIS SARTA, in order.
  fm1 = 650:0.625:1095;
  fm2 = 1210:1.25:1750;
  fm3 = 2155:2.5:2550;
  fm4 = 647.5:0.625:649.375;
  fm5 = 1095.625:0.625:1097.5;
  fm6 = 1205.00:1.25:1208.75;
  fm7 = 1751.25:1.25:1755;
  fm8 = 2145.00:2.5:2153.50;
  fm9 = 2552.5:2.5:2560;
  fm = [fm1';fm2';fm3';fm4';fm5';fm6';fm7';fm8';fm9'];


  % Get head.vchan from fm definitions above
  head.ichan = (1:1329)';
  head.vchan = fm;
  head.ptype = 0;
  head.pfields = 5;
  head.ngas = 0;
  head.nchan = length(fm);
  head.pltfid = -9999;
  head.instid = -9999;
  head.vcmax = -9999;
  head.vcmin = -9999;

  hattr = set_attr('header','pltfid','NPP');
  hattr = set_attr(hattr,'instid','CrIS');
  pattr = set_attr(pattr,'iudef(1,:)','Reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}');

end


