function stJobEntry = pop_job_table(taskid)

iNodeID = str2num(getenv('SLURM_PROCID'));
if length(iNodeID) == 0
    iNodeID = 99;
end

sMYSQL = 'mysql -h maya-mgt -u strow -pokdictuv strow';

% select one entry from the job management table that hasn't been
% done yet. Immediately update with this processor's node_id to try
% to lock the row out from further requests. 
sPOPSQL = sprintf(['echo "set @B=%d;' ...
                   'select @A:=entry_id as entry_id, year, doy from ' ...
                   'JobManagement where task_id = @B and node_id ' ...
                   'is null limit 1 for update;' ...
                   'update JobManagement set node_id = %d,' ...
                   'node_start = now() where task_id = @B and ' ...
                   'entry_id = @A;' ...
                   'set @A=0;"'], taskid, iNodeID);

% execute the table pop and get a day that is not being processed
[status, cmdout] = system([sPOPSQL ' | ' sMYSQL ' | head -2 | tail ' ...
                    '-1']);

stJobEntry = struct('entry',0, 'year',0, 'doy',0);

if length(cmdout) > 0
    % parse cmdout to entry_id, year and doy
    iTokens = str2num(cmdout);
    stJobEntry.entry = iTokens(1);
    stJobEntry.year = iTokens(2);
    stJobEntry.doy = iTokens(3);
end

end
