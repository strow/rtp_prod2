function batch_iasi_rtp(mondate,subset)

% script to process one months worth of IASI RTP files by generating an
% array of slurm jobs, one for each day. Each day will process all granules
% that are available for that day.
%
% INPUTs: 'year/month', e.g. '2012/01'
%         'subset'  e.g. 'random','dcc','sites','center','clear'
%
% DESCRIPTION:  Run this in the rtp_prod2/iasi sub-dir where all first-order dependent 
%  routines reside.
%  Given the month to process, a driver file is created to be used by the parent
%  proc. run_iasi_rtp.m.
%  This script writes a slurm batch script (overwriting if already exists), which calls
%  the parent proc.
%  Execution of the slurm batch job is initiated at the end.
% 
% ------------------------------------------------
% setup
% ------------------------------------------------
iasiAddPaths

iasihome = '/home/sbuczko1/git/rtp_prod2/iasi';
logfilepath = '/home/sbuczko1/LOGS/sbatch';

% ------------------------------------------------
% Prep the requested jobs
% ------------------------------------------------
% check the date string
if (length(mondate) ~= 7) fprintf(1,'Error in date format\n'); return; end;
syr = mondate(1:4);      smo = mondate(6:7);
nyr = str2num(syr);      nmo = str2num(smo);
if( nyr < 2007 | nyr > 2019 ) fprintf(1,'Error: year out of range\n'); return; end;
if( nmo < 1 | nmo > 12 ) fprintf(1,'Error: month out of range\n'); return; end;
endday = eomday(nyr, nmo);   
njobs = endday;

% define the driver file
dfname = ['iasi1_rtp_' syr smo '_' subset '_drv.mat'];
dname = fullfile('./run', dfname);

% delete date file if already exists
if(exist(dname,'file') == 2) delete(dname); end


% generate a cell array of dates to pass to the parent script
clear cellDates;
for i = 1:endday
  cellDates{i} = sprintf('%4d/%02d/%02d',nyr, nmo, i);
end

% save this structure for use by the parent script
save(dname,'cellDates');

% -----------------------------
% write the slurm batch script
% -----------------------------
batch = ['./run/batch_iasi1_' syr smo '_' subset '_rtp.slurm'];
FH = fopen(batch,'w');
fprintf(FH,'#!/bin/bash\n\n');

fprintf(FH,'#SBATCH --job-name=iasiRTP\n');
fprintf(FH,'#SBATCH --partition=high_mem\n');
fprintf(FH,'#SBATCH --qos=medium+\n');
fprintf(FH,'#SBATCH --account=pi_strow\n');
fprintf(FH,'#SBATCH --time=07:30:00\n');
%%fprintf(FH,'#SBATCH --constraint=hpcf2013\n');
fprintf(FH,'#SBATCH -N1\n');
fprintf(FH,'#SBATCH --output=%s/iasiRTP_slurm-%%N.%%A.%%a.out\n', ...
                   logfilepath);
fprintf(FH,'#SBATCH --error=%s/iasiRTP_slurm-%%N.%%A.%%a.err\n', ...
                   logfilepath);
fprintf(FH,'#SBATCH --mem=14000\n');
fprintf(FH,'#SBATCH --cpus-per-task 1\n');
fprintf(FH,'#SBATCH --array=1-%d\n\n',njobs);  %   -%d\n\n',njobs);         % was njobs

fprintf(FH,'MATLAB=''matlab''\n');
fprintf(FH,'MATOPTS='' -nodisplay -nojvm -nosplash''\n\n');

param = {dfname,subset};
junk = sprintf('$MATLAB $MATOPTS -r "addpath(''%s'');iasiAddPaths;run_iasi1_rtp(''%s'',''%s'');exit"',iasihome,param{:});
fprintf(FH,'%s\n',junk);

fclose(FH);

% -------------------------------------------
% now run the batch script
% -------------------------------------------
% $$$ 
% $$$ command = sprintf('sbatch %s',batch);
% $$$ [status,cmdout] = system(command);
% $$$ fprintf(1,'%s\n',cmdout);

