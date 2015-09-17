function run_iasi_rtp(dateFile,subset)

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

ddc = load(dateFile);

nslurm   = str2num(getenv('SLURM_ARRAY_TASK_ID'));
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
if(mydnum < 733255) fprintf(1,'Date too early\n'); return; end
today = datenum(date);
if(mydnum > today) fprintf(1,'Date is in the future!\n'); return; end;

% construct source path and get granule list for IASI-1.
clear inPath;
inPath = '/asl/data/IASI/L1C/';
syr = sdate(1:4);   smo = sdate(6:7); sdy = sdate(9:10);
jdy = datenum(syr,'yyyy') - mydnum + 1;
inPath = [inPath syr '/' smo '/' sdy '/'];

fnLst = dir(strcat(inPath, 'IASI_xxx_1C_M02*'));
fprintf(1,'Found %d granule files to process\n',length(fnLst));

for ifn = 1:numel(fnLst)  % 56:61   %
  infile = fnLst(ifn).name;
  fprintf(1,'Processing %d\t %s\n',ifn, infile);
  create_iasi_rtp([inPath infile],subset);
end

end % of function
