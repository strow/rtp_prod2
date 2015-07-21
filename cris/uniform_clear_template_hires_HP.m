function [pout] = uniform_clear_template_hires_hp(head, hattr, prof, pattr);
%
% Run the CrIS xuniform.m and xfind_clear.m codes for a Proxy data
% file and save some results. The input RTP should contain unapodized
% (ie boxcar) radiance along with profile and emissivity.
% input
%    [h,ha,p,pa] come from reading in an rtp file
%    assumes rcalc exists
% ouput
%    prof = p, but with added field p.iudef having the settings of 1,2,4,8
%         = where 1,2,4,8 are uniform clear, site, dcc, random

% Created: 05 May 2011, Scott Hannon - based on xuniform_clear_example.m
% Modified: 15 June 2015, Sergio Machado - based on above, substitute hi res chan set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Uniformity test channel ID numbers
idtestu = [276; 503; 762];
% The corresponding approximate channel freqs [wn] are:
%          [820 960 1231]

% Clear test channel IDs must include all those internally hardcoded
% in "find_clear.m".
idtestc=[  276;   336;    425;   503;   635;    679;     698;   714;     762];
% The corresponding approximate channel freqs [wn] are:
%      [819.375;856.875;912.5;961.25;1043.75;1071.25;1083.125;1093.125;1232.5];

% Name of KLAYERS and SARTA executables for clear detection calcs
KLAYERS= '/asl/packages/klayersV205/BinV201/klayers_airs';
SARTA  = '/asl/packages/sartaV108/BinV201/sarta_crisg4_nov09_wcon_nte';  %% lores
SARTA  = '/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte';    %% hires

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath /asl/rtp_prod/cris
addpath /asl/rtp_prod/cris/unapod
addpath /asl/rtp_prod/cris/uniform   % xuniform, site_dcc_random
addpath /asl/rtp_prod/cris/clear     % xfind_clear, proxy_box_to_ham

addpath /asl/matlib/aslutil        % mktemp
addpath /asl/matlib/h4tools        % rtpread, rtpwrite
addpath /asl/matlib/rtptools       % subset_rtp

%%%
prof.findex = ones(1,length(prof.findex),'int32');
%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% we need to save this, as we keep getting rid of guard channels
head0 = head;
prof0 = prof;
orig_robs = prof.robs1;
orig_rcalc = prof.rcalc;

%%%%%%%%%%%%%%%%%%%%%%%%%
%% Steve B. has these lines in his CrIS hi-res processing
%% Convert IASI radiances to CrIS
% opt.hapod = 0;  % Want sinc from iasi2cris
% opt.resmode = 'hires2'; % CrIS mode after Dec. 4, 2014
% Convert Iasi to CrIS
% [tmp_rad_cris, f_cris] = iasi2cris(rad_iasi,fiasi,opt);
%%
%% so we NEED to Convert boxcar (ie unapodized) to Hamming apodization

disp('running proxy_box_to_ham_hires')
[rad_ham,cal_ham] = cris_box_to_ham_hires(head.ichan, prof.robs1, prof.rcalc, 4);

%%%%%%%%%%%%%%%%%%%%%%%%%

% Note: the RTP structures are now temporary variables with hamming!!!!
% apodized radiances. Before outputing the subsetted RTP it will be necessary to
% re-substitude these with orig_robs and orig_rcalc

woo = find(head.ichan >= 1 & head.ichan <= 2211);
head.ichan = head.ichan(woo);
head.vchan = head.vchan(woo);
head.nchan = length(woo);
prof.robs1 = rad_ham;
prof.rcalc = cal_ham;
prof.calflag = prof.calflag(woo,:);

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
if ~isfield(prof,'rcalc')
  disp('this is where the calls to klayers and sarta would have been');
  error('since this is CRIS hires, expect rcalc field (from sarta iasi converted to cris) already supplied')
end  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Run xfind_clear
disp('running xfind_clear_hires')
[iflagsc, bto1232, btc1232] = xfind_clear_hires(head, prof, 1:nobs);
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
   [head, pout] = subset_rtp(head,prof,[],[],ikeep);
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

if iPlot > 0
  ff = head.vchan(1:2223);
  figure(1); 
  plot(pout.stemp,rad2bt(ff(732),pout.robs1(732,:)),'bo',...
       pout.stemp,rad2bt(ff(732),pout.rcalc(732,:)),'rs',...
       pout.stemp,pout.stemp,'k')
  grid
  title('Blue = obs   Red = cal'); xlabel('stemp'); ylabel('BT1232')

  figure(2); 
  tobs = rad2bt(ff,pout.robs1(1:2223,:)); tobs = real(tobs);
  tcal = rad2bt(ff,pout.rcalc(1:2223,:)); tcal = real(tcal);
    plot(ff,nanmean(tobs'-tcal'),ff,nanstd(tobs'-tcal'),'r')
  title('Blue = bias   Red = std'); xlabel('wavenumber cm-1'); ylabel('BT (K)')
end

%%% end of program %%%
