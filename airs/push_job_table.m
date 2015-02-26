function push_job_table(iTaskID, sJobName, iDoy, iYear)

sMYSQL = 'mysql -h maya-mgt -u strow -pokdictuv strow';
sSQL = sprintf(['echo "insert into JobManagement (task_id, year, ' ...
                'doy, task_name) values (%d, %d, %d, \\"%s\\");"'], iTaskID, iYear, ...
               iDoy, sJobName);

[status, cmdout] = system([sSQL ' | ' sMYSQL]);


end