function close_job_table_entry(iTaskID, iEntryID)

% close out day by adding processing end time to db table
sSQL = sprintf(['echo "update JobManagement set node_end=now() ' ...
                'where task_id = %d and entry_id = %d;"'], ...
               iTaskID, iEntryID);
sMYSQL = 'mysql -h maya-mgt -u strow -pokdictuv strow';
[status, cmdout] = system([sSQL ' | ' sMYSQL]);

end