function fill_job_table_range (startyear, startdoy, endyear, enddoy, ...
                               iTaskID, sJobName)

% build start and end dates for this processor
ydStartAll = sprintf('%4d%03d', startyear, startdoy);
ydEndAll = sprintf('%4d%03d', endyear, enddoy);

dtStart = datetime(ydStartAll, 'InputFormat', 'yyyyDDD')
dtEnd = datetime(ydEndAll, 'InputFormat', 'yyyyDDD')

dtDateList = dtStart:dtEnd;
iNumDaysToProc = length(dtDateList);

for i=1:iNumDaysToProc
    dtDate = dtDateList(i);
    iDoy = day(dtDate, 'dayofyear');
    iYear = year(dtDate);

    push_job_table(iTaskID, sJobName, iDoy, iYear);
end

end

