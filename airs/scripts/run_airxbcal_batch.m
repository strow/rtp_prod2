
function run_airxbcal_batch(startdoy, startyear, enddoy, endyear)

fprintf(1, '>> Executing run_airxbcal_batch');
fprintf(1, ['>>>> startdoy = %03d\n>>>> startyear = %4d\n>>>> enddoy ' ...
            '= %03d\n>>>> endyear = %4d\n\n'], startdoy, startyear, ...
        enddoy, endyear);

iProcID = str2num(getenv('SLURM_PROCID'));
iNumProcs = str2num(getenv('SLURM_NPROCS'));

% build start and end dates for this processor
ydStartAll = sprintf('%4d%03d', startyear, startdoy);
ydEndAll = sprintf('%4d%03d', endyear, enddoy);

dtStart = datetime(ydStartAll, 'InputFormat', 'yyyyDDD')
dtEnd = datetime(ydEndAll, 'InputFormat', 'yyyyDDD')

dtDateList = dtStart:dtEnd;
iNumDaysToProc = length(dtDateList);

iDaysPerCore = floor(iNumDaysToProc/iNumProcs);
iProcIndex = iProcID*iDaysPerCore;

fprintf(1, ['>>>> ProcID = %d\n>>>> NumProcs = %d\n>>>> DaysPerCore ' ...
            '= %d\n>>>> ProcIndex = %d\n>>> NumDays to proc = %d\n'], iProcID, iNumProcs, ...
        iDaysPerCore, iProcIndex, iNumDaysToProc);
for i=((iProcID*iDaysPerCore)+1):min(((iProcID+1)*iDaysPerCore), ...
                                        length(dtDateList))
    fprintf(1, 'run_airxbcal_batch: processing day %d, year %d\n', ...
            day(dtDateList(i), 'dayofyear'), year(dtDateList(i)))

    create_airxbcal_rtp(day(dtDateList(i), 'dayofyear'), year(dtDateList(i)));
end
end