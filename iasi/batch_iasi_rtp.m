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
cd /home/sbuczko1/git/rtp_prod2/iasi/run/
addpath /asl/packages/rtp_prod2/iasi
addpath /asl/packages/rtp_prod2/iasi/readers

% ------------------------------------------------
% Prep the requested jobs
% ------------------------------------------------
% check the date string
if (length(mondate) ~= 7) fprintf(1,'Error in date format\n'); return; end;
syr = mondate(1:4);      smo = mondate(6:7);
nyr = str2num(syr);      nmo = str2num(smo);
if( nyr < 2007 | nyr > 2015 ) fprintf(1,'Error: year out of range\n'); return; end;
if( nmo < 1 | nmo > 12 ) fprintf(1,'Error: month out of range\n'); return; end;
endday = eomday(nyr, nmo);   
njobs = endday;

% define the driver file
dfname = ['iasi_rtp_' syr smo '_drv.mat'];

% delete date file if already exists
if(exist(dfname,'file') == 2) delete(dfname); end


% generate a cell array of dates to pass to the parent script
clear cellDates;
for i = 1:endday
  cellDates{i} = sprintf('%4d/%02d/%02d',nyr, nmo, i);
end

% save this structure for use by the parent script
save(dfname,'cellDates');

% -----------------------------
% write the slurm batch script
% -----------------------------
batch = './batch_iasi_rtp.slurm';
FH = fopen(batch,'w');
fprintf(FH,'#!/bin/bash\n\n');

fprintf(FH,'#SBATCH --job-name=iasiRTP\n');
%fprintf(FH,'#SBATCH --partition=strow\n');
fprintf(FH,'#SBATCH --qos=medium\n');
fprintf(FH,'#SBATCH --account=pi_strow\n');
fprintf(FH,'#SBATCH --time=05:30:00\n');
%%fprintf(FH,'#SBATCH --constraint=hpcf2013\n');
fprintf(FH,'#SBATCH -N1\n');
fprintf(FH,'#SBATCH --output=iasiRTP_slurm-%%N.%%A.%%a.out\n');
fprintf(FH,'#SBATCH --error=iasiRTP_slurm-%%N.%%A.%%a.err\n');
fprintf(FH,'#SBATCH --mem=9000\n');
fprintf(FH,'#SBATCH --cpus-per-task 1\n');
fprintf(FH,'#SBATCH --array=1-%d\n\n',njobs);  %   -%d\n\n',njobs);         % was njobs

fprintf(FH,'MATLAB=''/usr/cluster/matlab/2015b/bin/matlab''\n');
fprintf(FH,'MATOPTS='' -nodisplay -nojvm -nosplash''\n\n');

param = {dfname,subset};
junk = sprintf('$MATLAB $MATOPTS -r "addpath(''/asl/packages/rtp_prod2/iasi'');run_iasi_rtp(''%s'',''%s''); exit"',param{:});
fprintf(FH,'%s\n',junk);

fclose(FH);

% -------------------------------------------
% now run the batch script
% -------------------------------------------
% $$$ 
% $$$ command = sprintf('sbatch %s',batch);
% $$$ [status,cmdout] = system(command);
% $$$ fprintf(1,'%s\n',cmdout);

