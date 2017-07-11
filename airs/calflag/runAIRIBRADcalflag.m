function runAIRIBRADcalflag ( year, daynumstart, daynumend)

% wrapper function to call readAIRIBRADcalflag over the range of
% days in YYYY/daynumstart:YYYY/daynumend in the AIRIBRAD/ data
% hierarchy 

% this function exists at this point, primarily to allow splitting
% data processing of multiple years over several HPC nodes
addpath('/home/sbuczko1/prgdir/src/matlab');

aStart = tic;  % let's build some timing statistics

for i=daynumstart:daynumend;
    bStart = tic;
    readAIRIBRADcalflag(year,i);
    bRun = toc(bStart);
    fprintf(1, '\t\tDay processed in %f seconds.\n', bRun);
end;

aRun = toc(aStart);
fprintf(1, '*** Script processing time %f seconds ***\n', aRun);
fprintf(1, 'End of processing\n');

end