function [head, hattr, prof, pattr] = create_iasi_allfov_rtp(fnIasiIn)

% NAME
%   
%
% SYNOPSIS
%   [head, hattr, prof, pattr] = create_iasi_rtp(fnIasiIn)
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
% ********  run paths.m first *************
%addpath /asl/rtp_prod2/grib       % fill_ecmwf.m fill_era.m
%addpath /asl/rtp_prod2/emis       % rtp_add_emis_single.m
%addpath /asl/rtp_prod2/util       % seq_match.m, rtpadd_usgs_10dem.m
%addpath /asl/matlib/rtptools      % set_attr.m

subset = 'allfov';

% Generate save file from input file: (expect: IASI_xxx_1C_M02_20130101000254Z_20130101000557Z)
clear savPath;
%%savPath = '/asl/s1/chepplew/projects/iasi/rtpprod/';
savPath = ['/asl/rtp/rtp_iasi1/' subset '/'];

addpath /asl/packages/rtp_prod2/grib       % fill_ecmwf.m fill_era.m
addpath /asl/packages/rtp_prod2/emis       % rtp_add_emis_single.m
addpath /asl/packages/rtp_prod2/util       % seq_match.m, rtpadd_usgs_10dem.m
addpath /asl/matlib/rtptools      % set_attr.m

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
    ~strcmp(subset,'dcc') & ~strcmp(subset,'sites') & ~strcmp(subset,'allfov'))
  fprintf(1,'Invalid subset option %s\n', subset);
  return
end

%
clear hd ha pd pa;
hd = struct; ha = struct; pd = struct; pa = struct;
head = struct; hattr = struct; prof = struct; pattr = struct;
SKIP = 0;                                     % in case no profiles after subsetting

% Load up one granule into an RTP structure (pa returns with 1:3 filled)
% with trap for error in readl1c_epsflip_all returned variables are set to 'NULL'

%%%fprintf(1,'call iasi2rtp\n');
[hd ha pd pa] = iasi2rtp(fnIasiIn);
%if (strcmp(class(hd), 'char')) 
%  if(strcmp(hd,'NULL')) 
%    fprintf(1,'Returning from create_iasi_rtp for next granule\n');
%    head ='NULL'; hattr='NULL';prof='NULL';pattr='NULL';
%    return; 
%  end
%end
if(isfield(pd,'N'))
  if(strcmp(pd.N,'NULL'))
    fprintf(1,'Problem in iasi2rtp: returning from create_iasi_rtp\n'); 
    %%%%head.N ='NULL'; hattr.N='NULL';prof.N='NULL';pattr.N='NULL';
    prof.N='NULL';
    return; 
  end
end

% trap bad granule data using quality flag
qbad = find(pd.robsqual > 0);
if(qbad) 
  fprintf(1,'\t %d bad obs trapped\n',numel(qbad));
%  [hd pd] = subset_rtp(hd, pd, [], [], qgood);
end

% check dimensions (number of FORs written to head_attr{4} )
nax  = cell2mat(ha{4}(3));
nobs = nax * 4;

% Add model data
% $$$ [pd, hd, pa] = fill_era(pd, hd, pa);
[pd, hd, pa] = fill_ecmwf(pd, hd, pa);

% Update header to record profile has obs and model data
hd.pfields = 5;

% Add surface geology
[hd ha pd pa] = rtpadd_usgs_10dem(hd,ha,pd,pa);

% Add Dan Zhou's emissivity and Masuda emis over ocean (dep: seq_match.m)
[pd pa] = rtp_add_emis_single(pd,pa);

% at this point there are 6 profile attributes defined and set.

% since we aren't subsetting, there should be a plethora of obs and
% no need to skip further processing
SKIP=0;

% ----------------------------------------
%          Run klayers & sarta
% ----------------------------------------
% if no profiles are available after subsetting then skip the rest
%fprintf(1,'SKIP = %d\n',SKIP);
if(~SKIP)
  %fprintf(1,'Running klayers and sarta\n');
  %disp(hd);
  % trap bad observations if there are no good ones return:
  qgood   = find(pd.robsqual == 0);
  if(numel(qgood) == 0)
    fprintf(1,'>>> Trapped zero good profiles before RTA calc\n');
    head.N ='NULL'; hattr.N='NULL';prof.N='NULL';pattr.N='NULL';
    return; 
  end
  [hd pd] = subset_rtp(hd, pd, [], [], qgood);

  % first split the spectrum & save a copy of each half

  tmp = mktemp();
  outfiles = rtpwrite_12(tmp,hd,ha,pd,pa);
  s1Path = '/tmp/';
  %disp(['tmp = ', tmp]);

  ifn_1 = outfiles{1};     ifn_2 = outfiles{2};
  ofn_1 = [tmp '.kla_1'];  ofn_2 = [tmp '.kla_2'];
  ofn_3 = [tmp '.sar_1'];  ofn_4 = [tmp '.sar_2'];

  % run klayers on first half
  %unix([klayers_exec ' fin=' ifn_1 ' fout=' ofn_1 ' > ' s1Path '/klayers_stdout']);
  unix([klayers_exec ' fin=' ifn_1 ' fout=' ofn_1 ' > /dev/null']);

  % run sarta on first half
  %eval(['! ' sarta_exec ' fin=' ofn_1 ' fout=' ofn_3 ' > sartastdout1.txt']);
  eval(['! ' sarta_exec ' fin=' ofn_1 ' fout=' ofn_3 ' > /dev/null']);

  % run klayers on second half
  %unix([klayers_exec ' fin=' ifn_2 ' fout=' ofn_2 ' > ' s1Path '/klayers_stdout']);
  unix([klayers_exec ' fin=' ifn_2 ' fout=' ofn_2 ' > /dev/null']);

  % run sarta on second half
  %eval(['! ' sarta_exec ' fin=' ofn_2 ' fout=' ofn_4 ' > sartastdout1.txt']);
  eval(['! ' sarta_exec ' fin=' ofn_2 ' fout=' ofn_4 ' > /dev/null']);

  % read the results files back in
  cfin = [tmp '.sar'];

  [hds has pds pas] = rtpread_12(cfin);

  % Use original profile struct (after model) as base and stuff
  % rcalcs from pds into it
  pd.rcalc = pds.rcalc;
  
  % ------------------------------------------
  %      save file and wrap up
  % ------------------------------------------
  if(~SKIP)
    savF = [savPath savFil];
    fprintf(1,'Saving %s\n',savF);
    res  = rtpwrite_12(savF, hd, ha, pd, pa);

  % -------------------------------------------
  %     or return structure for merging
  % -------------------------------------------  
    head=hd; hattr=ha; prof=pd; pattr=pa;

  end

  % silently delete temporary files:
  unlink(ifn_1); unlink(ifn_2); unlink(ofn_1); unlink(ofn_2); unlink(ofn_3);
  unlink(ofn_4); unlink(tmp);

end   % of SKIP=1

if(SKIP)        % SKIP = 1 so no profiles
    %%%head = 'NULL'; hattr = 'NULL'; pattr = 'NULL';
    prof.N = 'NULL'; head=hd; hattr=ha; pattr=pa;
end

end  % of function
