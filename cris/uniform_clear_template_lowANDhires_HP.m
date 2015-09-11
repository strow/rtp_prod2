function [pout] = uniform_clear_template_lowANDhires_HP(head, hattr, prof, pattr, idtestu, idtestc);
%
% Run the CrIS xuniform.m and xfind_clear.m codes for a Proxy data
% file and save some results. The input RTP should contain unapodized
% (ie boxcar) radiance along with profile and emissivity.
% input
%    [h,ha,p,pa] come from reading in an rtp file
%    idtestu, idtestc as needed for (u)niformity and (c)lear tests : optional args
%      if they are sent in, code does not really check how "sane" they are!
%      so best NOT to send them in (July 12, 2015)
%    does not assume rcalc exists in prof
%    runs SARTA and KLAYERS for lo-res
%
% ouput
%    prof = p, but with added field p.iudef having the settings of 1,2,4,8
%         = where 1,2,4,8 are uniform clear, site, dcc, random

% Created: 05 May 2011, Scott Hannon - based on xuniform_clear_example.m
% Modified: 15 June 2015, Sergio Machado - based on above, substitute hi res chan set or lo res chan set

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath /asl/rtp_prod/cris
addpath /asl/rtp_prod/cris/unapod
addpath /asl/rtp_prod/cris/uniform   % xuniform, site_dcc_random
addpath /asl/rtp_prod/cris/clear     % xfind_clear, proxy_box_to_ham

addpath /asl/matlib/aslutil        % mktemp
addpath /asl/matlib/h4tools        % rtpread, rtpwrite
addpath /asl/matlib/rtptools       % subset_rtp

%%%
head0 = head;
prof0 = prof;
prof.findex = ones(1,length(prof.rlat),'int32');
%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%disp(' >>>>>>>>>>>>>>>>>> TESTING rm rcalc >>>>>>>>>>>> ');
%if isfield(prof,'rcalc')
%  prof = rmfield(prof,'rcalc');
%  head.pfields = 5;
%end
%disp(' >>>>>>>>>>>>>>>>>> TESTING rm rcalc >>>>>>>>>>>> ');

%% we need to save this, as we keep getting rid of guard channels
orig_robs = prof.robs1;
if isfield(prof,'rcalc')
  orig_rcalc = prof.rcalc;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% >>> see lo_hi_res_similarchans.m
%% >>> notice for B1, chanIDs for lores = chanIDs for hires - 4
%% >>> once you go past B1 edge ( 1231 cm-1) then chanIDs for lo/hi res quite different

[mm,nn] = size(prof.robs1);
if mm ~= head.nchan
  error('hmm difference between h.nchan and size(p.robs1)');
end
if mm > 1400
  fprintf(1,'num of chans = %4i  must be hi-res \n',mm)
elseif mm < 1400
  fprintf(1,'num of chans = %4i  must be lo-res \n',mm)
end

idLOres_testu = [272; 499];
xufreq = [819.375; 961.25; 1232.5];
xcfreq = [819.375;856.875;912.5;961.25;1043.75;1071.25;1083.125;1093.125;1232.5];

if nargin == 4 & mm > 1400
  %% assume hi-res data
  % Uniformity test channel ID numbers
  idtestu = [276; 503; 762];
  % The corresponding approximate channel freqs [wn] are:
  %          [820 960 1231]; [819.375; 961.25; 1232.5];

  % Clear test channel IDs must include all those internally hardcoded
  % in "find_clear.m".
  idtestc=[  276;   336;    425;   503;   635;    679;     698;   714;     762];
  % The corresponding approximate channel freqs [wn] are:
  %      [819.375;856.875;912.5;961.25;1043.75;1071.25;1083.125;1093.125;1232.5];

elseif nargin == 5 & mm > 1400
  %% assume hi-res data

  % Clear test channel IDs must include all those internally hardcoded
  % in "find_clear.m".
  idtestc=[  276;   336;    425;   503;   635;    679;     698;   714;     762];
  % The corresponding approximate channel freqs [wn] are:
  %      [819.375;856.875;912.5;961.25;1043.75;1071.25;1083.125;1093.125;1232.5];

elseif nargin == 4 & mm < 1400
  %% assume lo-res data
  % Uniformity test channel ID numbers
  idtestu = [272; 499; 732];
  % The corresponding approximate channel freqs [wn] are:
  %          [820 960 1231]; [819.375; 961.25; 1232.5];  

  % Clear test channel IDs must include all those internally hardcoded
  % in "find_clear.m".
  idtestc=[  272;   332;    421;   499;   631;    675;     694;   710;     732];
  % The corresponding approximate channel freqs [wn] are:
  %      [819.375;856.875;912.5;961.25;1043.75;1071.25;1083.125;1093.125;1232.5];

elseif nargin == 5 & mm < 1400
  %% assume lo-res data

  % Clear test channel IDs must include all those internally hardcoded
  % in "find_clear.m".
  idtestc=[  272;   332;    421;   499;   631;    675;     694;   710;     732];  
  % The corresponding approximate channel freqs [wn] are:
  %      [819.375;856.875;912.5;961.25;1043.75;1071.25;1083.125;1093.125;1232.5];
end

if max(idtestu) > 717 & max(idtestc) > 717
  %% throw out last channel (1231 cm-1)
  idtestu = idtestu(1:end-1);
  idtestc = idtestc(1:end-1);
end

for ii = 1 : length(xufreq)
  xidtestu(ii) = find(head.vchan+0.01 >= xufreq(ii),1);
end
for ii = 1 : length(xcfreq)
  xidtestc(ii) = find(head.vchan+0.01 >= xcfreq(ii),1);  
end
%% throw out last channel (1231 cm-1)
xidtestu = xidtestu(1:end-1)';
xidtestc = xidtestc(1:end-1)';

if sum(idtestu-xidtestu) ~= 0
  disp('oops : the preset uniform chanID set is different than that we dynamically find from head.vchan ... resetting');
  idtestu
  xidtestu
  idtestu = xidtestu;
end

if sum(idtestc-xidtestc) ~= 0
  disp('oops : the preset clear chanID set is different than that we dynamically find from head.vchan ... resetting');
  idtestc
  xidtestc
  idtestc = xidtestc;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name of KLAYERS and SARTA executables for clear detection calcs
klayers = '/asl/packages/klayersV205/BinV201/klayers_airs';
sarta   = '/asl/packages/sartaV108/BinV201/sarta_crisg4_nov09_wcon_nte';  %% lores

if ~isfield(prof,'rcalc')

  id_offset = idLOres_testu - idtestu;    %% this is FOR SARTA LO RES CRIS!!!!
  id_offset = id_offset(1);
  
  disp('need rcalc, so have to run klayers and sarta')
  disp('since we are only using B1 in idtestc, can use sarta-cris')

  fip = mktemp('junk_cris_uniform_clear.ip.rtp');
  fop = mktemp('junk_cris_uniform_clear.op.rtp');
  frp = mktemp('junk_cris_uniform_clear.rp.rtp');
  fjunk = mktemp('junk_cris_uniform_clear.junk');    
  
  %% have to do some faking
  idtestcm = [idtestc-5; idtestc-4; idtestc-3; idtestc-2; idtestc-1];
  idtestcp = [idtestc+5; idtestc+4; idtestc+3; idtestc+2; idtestc+1];
  idtestcALL = sort([idtestcm; idtestc; idtestcp]) + id_offset;
  orig_idtestcALL = idtestcALL;
  bad = find(idtestcALL > 713);
  idtestcALL(bad) = (idtestcALL(bad)-713) + 1309;

  [hsub,psub] = subset_rtp(head,prof,[],idtestcALL,[]);
  hsub = rmfield(hsub,'vchan');
  
  if head.ptype == 0 & isfield(psub,'gas_1') & hsub.gunit(1) ~= 1
    rtpwrite(fip,hsub,hattr,psub,pattr);
    klayerser = ['!' klayers ' fin=' fip ' fout=' fop ' >& ' fjunk];
    eval(klayerser)
    sartaer = ['!' sarta ' fin=' fop ' fout=' frp ' >& ' fjunk];
    eval(sartaer)
    [hsubx,hax,psubx,pax] = rtpread(frp);
    rmer = ['!/bin/rm ' fip ' ' fop ' ' frp ' ' fjunk];
    eval(rmer);
    rcalc = zeros(size(prof.robs1));
    rcalc(orig_idtestcALL - id_offset,:) = psubx.rcalc;
    prof.rcalc = rcalc;
    head.pfields = 7;
  elseif head.ptype == 1 & isfield(psub,'gas_1') & hsub.gunit(1) == 1
    rtpwrite(fop,hsub,hattr,psub,pattr);
    sartaer = ['!' sarta ' fin=' fop ' fout=' frp ' >& ' fjunk];
    eval(sartaer)
    [hsubx,hax,psubx,pax] = rtpread(frp);
    rmer = ['!/bin/rm ' fop ' ' frp ' ' fjunk];
    eval(rmer);
    rcalc = zeros(size(prof.robs1));
    rcalc(orig_idtestcALL - id_offset,:) = psubx.rcalc;
    prof.rcalc = rcalc;
    head.pfields = 7;
  elseif ~isfield(psub,'gas_1')
    fprintf(1,'huh ???? no rcalc and hsub.pfields == %2i \n',hsub.pfields);
    error('cannot run klayers/sarta')
  elseif ~isfield(psub,'emis')
    fprintf(1,'huh ???? no emis\n',hsub.pfields);
    error('cannot run klayers/sarta')
  end
end  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Steve B. has these lines in his CrIS hi-res processing
%% Convert IASI radiances to CrIS
% opt.hapod = 0;  % Want sinc from iasi2cris
% opt.resmode = 'hires2'; % CrIS mode after Dec. 4, 2014
% Convert Iasi to CrIS
% [tmp_rad_cris, f_cris] = iasi2cris(rad_iasi,fiasi,opt);
%%
%% so we NEED to Convert boxcar (ie unapodized) to Hamming apodization

disp('running proxy_box_to_ham_hires')
if mm > 1400 
  [rad_ham,cal_ham] = cris_box_to_ham_hires(head.ichan, prof.robs1, prof.rcalc, 4);
else
  [rad_ham] = cris_box_to_ham(head.ichan, prof.robs1, 4);
  [cal_ham] = cris_box_to_ham(head.ichan, prof.rcalc, 4);  
end

%%%%%%%%%%%%%%%%%%%%%%%%%

% Note: the RTP structures are now temporary variables with hamming!!!!
% apodized radiances. Before outputing the subsetted RTP it will be necessary to
% re-substitude these with orig_robs and orig_rcalc

if mm > 1400
  woo = find(head.ichan >= 1 & head.ichan <= 2211);
elseif mm < 1400
  woo = find(head.ichan >= 1 & head.ichan <= 1305);   %%% ******* check this
end
head.ichan = head.ichan(woo);
head.vchan = head.vchan(woo);
head.nchan = length(woo);
prof.robs1 = rad_ham;
prof.rcalc = cal_ham;
if isfield(prof,'calflag')
  prof.calflag = prof.calflag(woo,:);
end

% Run xuniform
disp('running xuniform2')
[dbtun, mbt] = xuniform2(head, prof, idtestu);
nobs = length(dbtun);
ibad1 = find(mbt < 150);

% /asl/rtp_prod/cris/uniform/site_dcc_random.m
% Run site_dcc_random
% Note: can use the same channels used in the uniform test
disp('running site_dcc_random')
iSergioRandom = -1;  %% just stick to Scott's code
iSergioRandom = +1;  %% change over to Sergio code
if iSergioRandom < 0
  [iflagso, isite] = site_dcc_random(head, prof, idtestu);
elseif iSergioRandom > 0

  [iflagso, isite] = site_dcc_random_cris_sergio(head, prof, idtestu);
  % [keep,keep_ind] = hha_lat_subsample_equal_area2_cris_hires(head,prof);
  % woo = find(iflagso == round(8));
  % fprintf(1,'replacing the %4i random from Scotts code with %4i from Sergio code \n',length(woo),length(keep));
  % iflagso(woo) =  iflagso(woo) - round(8);    %% so hopefully round(0)
  % iflagso(keep) = iflagso(keep) + round(8);   %% so hopefully round(8)
end

ibad2 = find(iflagso >= 32);
ibad = setdiff(ibad1,ibad2);
iflagso(ibad) = iflagso(ibad) + 32;
% Keep 2=site, 4=DCC, 8=random even if coastal=16 but not coastal only
iother = setdiff(find(iflagso >= 2 & iflagso <= 30),find(iflagso == 16));

%%%%%%%%%%%%%%%%%%%%%%%%%

% Subset RTP for the clear test channels (to speed up calcs)
% disp('subsetting RTP to clear test channels')
[head, prof] = subset_rtp(head, prof, [], idtestc, []);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Run xfind_clear
disp('running xfind_clear_loANDhires')
[iflagsc, bto1232, btc1232] = xfind_clear_loANDhires(head, prof, 1:nobs, idtestc);
iclear_sea    = find(iflagsc == 0 & abs(dbtun) < 0.5 & prof.landfrac <= 0.01);
iclear_notsea = find(iflagsc == 0 & abs(dbtun) < 1.0 & prof.landfrac >  0.01);
iclear = union(iclear_sea, iclear_notsea);

% Re-set prof and head
prof = prof0;
head = head0;

% Determine all indices to keep
iclrflag = zeros(1,nobs);
iclrflag(iclear) = 1;
ireason = iclrflag + iflagso;
% Reject any coastal clear FOVs that are not site or random
ireject = find(ireason == 17);
if (length(ireject) > 0)
   iclear = setdiff(iclear,ireject);
end

ikeep = union(iclear, iother);
nkeep = length(ikeep);
disp(['nclear=' int2str(length(iclear))])
disp(['nkeep=' int2str(nkeep)])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Subset RTP and save output

if (nkeep > 0)
   % Subset to RTP for {clear, site, DCC, random}
   [hout, pout] = subset_rtp(head,prof,[],[],ikeep);
   isite = isite(ikeep);
   iclrflag = iclrflag(ikeep);
   ireason = ireason(ikeep);

   % Cut ireason to 4 bits
   icut = find(ireason > 32);
   ireason(icut) = ireason(icut) - 32;
   icut = find(ireason > 16);
   ireason(icut) = ireason(icut) - 16;

   pout.clrflag = iclrflag;  
   if (~isfield(pout,'udef'))
      pout.udef = zeros(20,nkeep);
   end
   pout.udef(13,:) = dbtun(ikeep);
   pout.udef(14,:) = bto1232(ikeep);
   pout.udef(15,:) = btc1232(ikeep);
   if (~isfield(pout,'iudef'))
      pout.iudef = zeros(10,nkeep);
   end
   pout.iudef(1,:) = ireason;
   pout.iudef(2,:) = isite;

   junk = set_attr(pattr, 'udef(13,:)', 'spatial uniformity test dBT {dbtun}');
   pattr = set_attr(junk, 'udef(14,:)', 'BTobs 1232 wn {bto1232}');
   junk = set_attr(pattr, 'udef(15,:)', 'BTcal 1232 wn {btc1232}');
   pattr = set_attr(junk, 'iudef(1,:)', ...
      'selection reason: 1=clear, 2=site, 4=DCC, 8=random {reason}');
   junk = set_attr(pattr, 'iudef(2,:)', 'fixed site number {sitenum}');
   pattr = junk;
   iPlot = +1;
else
   disp('no FOVs selected')
   pout = [];
   iPlot = -1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% $$$ if iPlot > 0 & isfield(pout,'rcalc') & hout.nchan > 1400
% $$$   ff = hout.vchan(1:2223);
% $$$   figure(1); 
% $$$   plot(pout.stemp,rad2bt(ff(732),pout.robs1(732,:)),'bo',...
% $$$        pout.stemp,rad2bt(ff(732),pout.rcalc(732,:)),'rs',...
% $$$        pout.stemp,pout.stemp,'k')
% $$$   grid
% $$$   title('Blue = obs   Red = cal'); xlabel('stemp'); ylabel('BT1232')
% $$$ 
% $$$   figure(2); 
% $$$   tobs = rad2bt(ff,pout.robs1(1:2223,:)); tobs = real(tobs);
% $$$   tcal = rad2bt(ff,pout.rcalc(1:2223,:)); tcal = real(tcal);
% $$$     plot(ff,nanmean(tobs'-tcal'),ff,nanstd(tobs'-tcal'),'r')
% $$$   title('Blue = bias   Red = std'); xlabel('wavenumber cm-1'); ylabel('BT (K)')
% $$$ 
% $$$ elseif iPlot > 0 & isfield(pout,'rcalc') & hout.nchan < 1400
% $$$   ff = hout.vchan(1:1305);
% $$$   figure(1); 
% $$$   plot(pout.stemp,rad2bt(ff(732),pout.robs1(732,:)),'bo',...
% $$$        pout.stemp,rad2bt(ff(732),pout.rcalc(732,:)),'rs',...
% $$$        pout.stemp,pout.stemp,'k')
% $$$   grid
% $$$   title('Blue = obs   Red = cal'); xlabel('stemp'); ylabel('BT1232')
% $$$ 
% $$$   figure(2); 
% $$$   tobs = rad2bt(ff,pout.robs1(1:1305,:)); tobs = real(tobs);
% $$$   tcal = rad2bt(ff,pout.rcalc(1:1305,:)); tcal = real(tcal);
% $$$     plot(ff,nanmean(tobs'-tcal'),ff,nanstd(tobs'-tcal'),'r')
% $$$   title('Blue = bias   Red = std'); xlabel('wavenumber cm-1'); ylabel('BT (K)')
% $$$ end

%%% end of program %%%
