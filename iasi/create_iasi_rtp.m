function create_iasi_rtp(fnIasiIn, subset)

% NAME
%   
%
% SYNOPSIS
%   
%
% INPUTS
%   
%
% OUTPUTS
%   
%
% DISCUSSION
%   
% process a single IASI granule file
%
% DEPENDENCIES (of the first order)
%  a). local files:
%      iasi2rtp.m, random_eq_area.m, fixedsite.m, imager_uniformity.m, spectral_uniformity.m,
%      spectral_clarity.m, {klayers and sarta executables}. 
%  b). remote files (by addpath)
%      fill_era.m, rtp_add_emis_single.m,  rtpadd_usgs_10dem.m, seq_match.m, 
%      set_attr.m, subset_rtp.m, rtpwrite_12.m, rtpread_12.m, iasi_clear_wn.m
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set process directories

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte';

% add dependency paths
addpath /asl/rtp_prod2/grib       % fill_ecmwf.m fill_era.m
addpath /asl/rtp_prod2/emis       % rtp_add_emis_single.m
addpath /asl/rtp_prod2/util       % seq_match.m, rtpadd_usgs_10dem.m
addpath /asl/matlib/rtptools      % set_attr.m

% Generate save file from input file: (expect: IASI_xxx_1C_M02_20130101000254Z_20130101000557Z)
clear savPath;
savPath = '/asl/s1/chepplew/projects/iasi/rtpprod/';
[pathstr,fnamin,ext] = fileparts(fnIasiIn);
[pparts,pmatches]    = strsplit(pathstr,'/');      % parts 6=year, 7=mon, 8=day.
[fparts,fmatches]    = strsplit(fnamin,'_');       % part 5=granule start time.
savPath = [savPath pparts{6} '/' pparts{7} '/' pparts{8} '/'];
savFil  = [fparts{5} '_' subset '.rtp'];

% if save directory does not exist - create it:
 if(~exist(savPath,'dir')) mkdir(savPath); end
 
% check and process subsetting option ('clear', 'random', 'center', 'dcc', 'sites')
subset = lower(subset);
if(~strcmp(subset,'clear') & ~strcmp(subset,'random') & ~strcmp(subset,'center') & ...
    ~strcmp(subset,'dcc') & ~strcmp(subset,'sites') )
  fprintf(1,'Invalid subset option %s\n', subset);
  return
end

%
clear hd ha pd pa;
SKIP = 0;                                     % in case no profiles after subsetting

% Load up one granule into an RTP structure (pa returns with 1:3 filled)
[hd ha pd pa] = iasi2rtp(fnIasiIn);

% check dimensions (written to head_attr{3} )
nax  = cell2mat(ha{3}(3));
nobs = nax * 4;

% Add model data
[pd, hd] = fill_era(pd, hd);

% Update header to record profile has obs and model data
hd.pfields = 5;

% Add surface geology
[hd ha pd pa] = rtpadd_usgs_10dem(hd,ha,pd,pa);

% Add Dan Zhou's emissivity and Masuda emis over ocean (dep: seq_match.m)
[pd pa] = rtp_add_emis_single(pd,pa);

% at this point there are 6 profile attributes defined and set.

% --------------------------------------------------
%                   Random FOV subset
% --------------------------------------------------
if(strcmp(subset,'random'))

%{
  ixtrackrand = [15];                 % which xtrack FOV to randomize
  randadj     = 0.4;                  % thinning factor for subsetting
  random_seed = int32(pd.rtime(1));
  rng(random_seed,'twister');
  bv8 = zeros(1,nobs,'single');
  randind = find(pd.xtrack == ixtrackrand);
  nind = length(randind);
  if(nind > 0)
    rand01 = rand([1,nind]);
    randlim = randadj*cos(pd.rlat(randind)*pi/180);
    ib = ind(find(rand01 <= randlim));
  end
%}

  [randreas indrand] = random_eq_area(pd);
  nrand = length(indrand);
  if(nrand == 0) SKIP = 1; end
  if(~SKIP) 
    [hd pd] = subset_rtp(hd, pd, [], [], indrand);  
  end
  
  % set profile attributes and udef() values  

end
% --------------------------------------------------
%                    fixed SITES subset
% --------------------------------------------------
if(strcmp(subset,'sites'))
  
  range_km = 55.5;                                     % fixed site matchup max range

  bv2   = zeros(1,nobs);
  [isiteind,isitenum] = fixedsite(pd.rlat,pd.rlon,range_km);
  isite = zeros(1,nobs);
  isite(isiteind) = isitenum;
  nsite = length(isiteind);
  bv2(isiteind)   = 2;

  if(nsite == 0) SKIP = 1; end

  % keep only the clear elements. if idcc = 0 then skip since subset_rtp won't work!
  if(~SKIP) [hd pd] = subset_rtp(hd, pd, [], [], isiteind);  end
 
  % set profile attributes and udef() values
  pa = set_attr(pa, 'iudef(2,:)', 'fixed site number');
  
  clear isiteind isitenum

end   % end of sites subset
% --------------------------------------------------
%                    CLEAR subset
% ---------------------------------------------------
if(strcmp(subset,'clear'))

  % Get Ocean, Land and Coastal. Note: modsst: from ecmwf/era, lsea: from usgs...
  isea       = zeros(nax,4,'single');
  iland      = zeros(nax,4,'single');
  icoast     = zeros(nax,4,'single');
    mylndfrc = reshape(pd.landfrac,[],4);
    ii       = find(mylndfrc < 0.01);
  isea(ii)   = 1;    clear ii;
    ii       = find( mylndfrc > 0.01 & mylndfrc < 0.99);
  icoast(ii) = 1;    clear ii;
    ii       = find( mylndfrc > 0.99);
  iland(ii)  = 1;    clear ii;
  modstemp = reshape(pd.stemp,[],4);      % spectral_clarity.m requires [n x 4];


  % Test image & spectral uniformity first (these can be done b4 sarta calculations):
  % Imager uniformity:
  [imageunflag btall btsub nall nsub stdall stdsub] = imager_uniformity(fnIasiIn);
  pd.udef(10,:) = reshape(imageunflag,[],nobs);
  pa = set_attr(pa,'udef(10,:)','Imager uniformity flag (1=uniform)');
  % iimagun = find(imageunflag == 1);
  
  % Spectral uniformity:
  [spectunflag dbt757u dbt820u dbt960u dbt1231u dbt2140u] = spectral_uniformity(...
      fnIasiIn, imageunflag);
  pd.udef(11,:) = reshape(spectunflag,[],nobs);
  pa = set_attr(pa,'udef(11,:)','Spectral uniformity flag (1=uniform)');
  % ispecun = find(spectunflag == 1);

  % Spectral clear:
  % spectral_clear arguments
  %%% Nominal
  %dbtqmin   = 0.3;
  %dbt820max = 3;
  %dbt960max = 2;
  %dbtsstmax = 5;
  %%% 20% tighter than nominal
  dbtqmin    = 0.36;
  dbt820max  = 2.4;
  dbt960max  = 1.6;
  dbtsstmax  = 5.0;

  [clearflag retsst dbtq dbt820 dbt960 dbtsst] = spectral_clarity(fnIasiIn,...
     isea, modstemp, spectunflag, dbtqmin, dbt820max, dbt960max, dbtsstmax);
  pd.udef(12,:) = reshape(clearflag,[],nobs);
  pa = set_attr(pa,'udef(12,:)','Spectral clarity flag (1=passed all tests)');
  % ispeclr = find(clearflag == 1);

  %
  ispeclr = find(clearflag == 1);       % 1 = spectral clear
  nspeclr = length(ispeclr);
  if(nspeclr == 0) SKIP = 1; end

  % keep only the clear elements.
  if(~SKIP) [hd pd] = subset_rtp(hd, pd, [], [], ispeclr); end
  
end   % of option 'clear'

% --------------------------------------
%              CENTRE FOVs
% --------------------------------------
if (strcmp(subset,'center'))

  icent = find(pd.xtrack == 15 | pd.xtrack == 16); 
  ncent = length(icent);
  
  % keep only the center subset
  [hd pd] = subset_rtp(hd, pd, [], [], icent);

  % apply profile attributes and udef() values
  
end     % of centre subset

% --------------------------------------
%              DCC subset
% --------------------------------------
if (strcmp(subset,'dcc'))
   idtestu   = [702; 1262; 2346];                % channel IDs for testing
   latmaxdcc = 60;                               % max |rlat| for dcc testing
   btmaxdcc  = 210;                              % max BT (K) for dcc testing
   
   ftest = hd.vchan(idtestu);
   rtest = pd.robs1(idtestu,:);
   ibad  = find(rtest < 1E-6);
   rtest(ibad) = NaN;
   btm   = nanmean(real(rad2bt(ftest,rtest)),1);
   ntest = numel(btm);
   clear rtest ftest;
   
   bv4  = zeros(1,ntest);
   idcc = find(btm <= btmaxdcc & abs(pd.rlat) <= latmaxdcc);
   ndcc = length(idcc);
   bv4(idcc) = 4;
   if(ndcc == 0) SKIP = 1; end

  % keep only the clear elements. if idcc = 0 then skip since subset_rtp won't work!
  if(~SKIP) [hd pd] = subset_rtp(hd, pd, [], [], idcc);  end

  % apply profile attributes and udef() values:

end

% ----------------------------------------
%          Run klayers & sarta
% ----------------------------------------
% if no profiles are available after subsetting then skip the rest
if(~SKIP)

  % first split the spectrum & save a copy of each half

  tmp = mktemp();
  outfiles = rtpwrite_12(tmp,hd,ha,pd,pa);
  s1Path = '/asl/s1/chepplew/tmp/';

  ifn_1 = outfiles{1};     ifn_2 = outfiles{2};
  ofn_1 = [tmp '.kla_1'];  ofn_2 = [tmp '.kla_2'];
  ofn_3 = [tmp '.sar_1'];  ofn_4 = [tmp '.sar_2'];

  % run klayers on first half
  unix([klayers_exec ' fin=' ifn_1 ' fout=' ofn_1 ' > ' s1Path '/klayers_stdout']);

  % run sarta on first half
  eval(['! ' sarta_exec ' fin=' ofn_1 ' fout=' ofn_3 ' > sartastdout1.txt']);

  % run klayers on second half
  unix([klayers_exec ' fin=' ifn_2 ' fout=' ofn_2 ' > ' s1Path '/klayers_stdout']);

  % run sarta on second half
  eval(['! ' sarta_exec ' fin=' ofn_2 ' fout=' ofn_4 ' > sartastdout1.txt']);

  % read the results files back in
  cfin = [tmp '.sar'];

  [hd ha pd pa] = rtpread_12(cfin);

  % -----------------------------------------------------
  %               CLEAR-2 subset - using sarta calcs
  % -----------------------------------------------------
  SKIP = 0;
  if(strcmp(subset,'clear'))
    % update number of profiles remaining
    nax2 = size(pd.rlat,2);
    
    [clrflags, bto1232, btc1232] = iasi_clear_wn(hd, pd, [1:nax2]);
    pd.udef(13,:) = clrflags;                  % already column vector [1xN] 
    pa = set_attr(pa,'udef(13,:)','clear window (0 = clear)');
     
    ikeep = find(clrflags == 0);
    nkeep = length(ikeep);
    if(nkeep == 0) SKIP = 1; end
    if(~SKIP) [hd pd] = subset_rtp(hd, pd, [], [], ikeep); end

  end   % end of CLEAR-2
      
  % ------------------------------------------
  %      save file and wrap up
  % ------------------------------------------
  if(~SKIP)
    savF = [savPath savFil];
      fprintf(1,'Saving %s\n',savF);
    res  = rtpwrite_12(savF, hd, ha, pd, pa);
  end
  

  % silently delete temporary files:
  unlink(ifn_1); unlink(ifn_2); unlink(ofn_1); unlink(ofn_2); unlink(ofn_3);
  unlink(ofn_4); unlink(tmp);


end   % of SKIP=1

end  % of function
