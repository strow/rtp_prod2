function run_iasi2_rtp(dateFile,subset)

% This version designed for use with batch_iasi_rtp.m
%   takes a file of days to process, assigning one day to one slurm array.

% For each task gets the list of IASI L1C granule files to process, passing them
%  to create_iasi_rtp.m

% Can be modified simply to run interactively by changing the parameter from
%   dateFile to 'sdate' with format 'YYYY/MM/DD' and commenting out first
%   paragraph..

% modified 9-Jul-2015. input data driver file supplied by batch_iasi_rtp.m
%          and designed to be run as SLURM array jobs.
%          first paragraph dealing with 'dateFile' added.
%
%-----------------------------------------------------------
% prep the batch job from the dateFile.
%-----------------------------------------------------------

    cd /home/sbuczko1/git/rtp_prod2/iasi/run
    addpath /asl/packages/rtp_prod2/emis
    addpath /asl/packages/rtp_prod2/util
    addpath /asl/packages/rtp_prod2/grib
addpath /home/sbuczko1/git/rtp_prod2/iasi
addpath /asl/packages/rtp_prod2/iasi/readers
addpath /asl/matlib_2015/aslutil  % for utc2tai2000 (replace this
                                  % with new time commands)
addpath /asl/matlib/aslutil

ddc = load(dateFile);

nslurm   = str2num(getenv('SLURM_ARRAY_TASK_ID'));
%%%%%nslurm = [];
ncompute = getenv('SLURM_NODELIST');

% if this script is run WIHTOUT the batch controller there will be no SLURM_ARRAY_TASK_ID
% and IF the dateFile is available then ONLY the first entry (day) will be processed.
if(isempty(nslurm)) nslurm = 1; end

cellName = cell2mat(fieldnames(ddc));            % assume single field.
fprintf(1,'this job date: %s\t subset: %s\n',ddc.(cellName){nslurm},subset);
fprintf(1,'this job compute node: %s\n',ncompute);
sdate = ddc.(cellName){nslurm};

% ---------------------------------------------------- %

% sanity check of date.
mydnum = datenum(sdate,'yyyy/mm/dd');
if(mydnum < 733043) fprintf(1,'Date too early\n'); return; end  % no early 2007/07.
today = datenum(date);
if(mydnum > today) fprintf(1,'Date is in the future!\n'); return; end;

% construct source path and get granule list for IASI-1.
clear inPath;
inPath = '/asl/data/IASI/L1C/';
syr = sdate(1:4);   smo = sdate(6:7); sdy = sdate(9:10);
jdy = datenum(syr,'yyyy') - mydnum + 1;
inPath = [inPath syr '/' smo '/' sdy '/'];

% dir is causing headaches on the lustre filesystem so we are
% moving toward using ls(), or running ls/find within a system
% statement and parsing results in its place. Here use ls(). Pass
% '-1' to system to make an easily parsable string (elements
% separated by \n newline, strip trailing spaces and split
fnLst1 = ls(strcat(inPath, 'IASI_xxx_1C_M01*'), '-1');  % use only
                                                           % gzipped
                                                           % granules
fnLst1stripped = strsplit(strtrim(fnLst1),'\n');

fprintf(1,'Found %d granule files to process\n',numel(fnLst1stripped));

clear sav_profs all_profs; fcnt = 0;
for ifn = 1:numel(fnLst1stripped)  % 56:61   %
                                   %for ifn = 1:20
    clear hdx hax pax;
    infile = fnLst1stripped{ifn};

    fnLst = dir(infile);
    if(fnLst.bytes > 2E7)                     % avoid deficient granules
        fprintf(1,'Processing %d\t %s\n',ifn, infile);

        [hdx, hax, pdx, pax] = create_iasi_rtp(infile,subset);
%    if (strcmp(class(hdx), 'char')) 
%      if(strcmp(pdx,'NULL'))
%        fprintf(1,'Continue to next granule\n'); 
%        continue; 
%      end
%    end
    if(isfield(pdx,'N'))
      if(strcmp(pdx.N,'NULL'))
        fprintf(1,'Continue to next granule\n'); 
        continue; 
      end
    end
    fcnt = fcnt + 1;
    % still hitting memory limits. a day of iasi clear is now pulling out
    % ~120k obs and we can only keep about 50k so, throw 1/2 away
    % right now to make room for processing and do a trimming cut
    % later for the output limits
    temp = rtp_sub_prof(pdx, randperm(length(pdx.rtime), ...
                                      floor(length(pdx.rtime)/2)));
    all_profs(fcnt) = temp;
    clear pdx temp;
  end

end
prof = structmerge(all_profs);
clear all_profs; 

% subset if nobs is greater than threshold lmax (to avoid hdf file size
% limitations and hdfvs() failures during rtp write/read
% later). Keeps dcc, site and random obs intact and reduces number
% of clear obs to meet threshold limit
lmax = 50000;
fprintf(1, '>>> *** %d pre-subset obs ***\n', length(prof.rtime));
if length(prof.rtime) > lmax
    fprintf(1, '>>>*** nobs > %d. subsetting clear... ', lmax);
    sav_profs = rtp_sub_prof(prof, randperm(length(prof.rtime), ...
                                            lmax));
    clear prof
    fprintf(1, 'Done ***\n');
    fprintf(1, '>>> *** %d subset obs ***\n', length(sav_profs.rtime));
end

% Save the hourly/daily RTP file
outpath = '/asl/rtp/rtp_iasi2';
savPath = fullfile(outpath, subset, syr);

if ~exist(savPath)
    mkdir(savPath)
end

  savFil  = ['iasi2_ecmwf_d' syr smo sdy '_' subset '.rtp'];
  savF    = fullfile(savPath, savFil);

  fprintf(1, '>>> Writing to output file: %s\n', savF);
  
  res = rtpwrite_12(savF, hdx, hax, sav_profs, pax);
  
end % of function
