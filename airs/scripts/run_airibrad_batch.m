function run_airxbcal_batch(iTaskID)

set_process_dirs
addpath(genpath(rtp_sw_dir));
addpath('~/git/slurmutil/matlab');

% pause to help elimnate db collisions on startup. Pause length is in
% seconds, based on relative processor id. Once running, natural
% variation in run length wil be our guard against collision. (no, not
% ideal...)
pause(str2num(getenv('SLURM_PROCID')));

iEntryID = str2num(getenv('SLURM_ARRAY_TASK_ID'));

while 1
       
    stJobEntry = pop_job_table(iTaskID, iEntryID);
    iEntryID = stJobEntry.entry;
    iDoy = stJobEntry.doy;
    iYear = stJobEntry.year;

    if iEntryID == 0
        % nothing returned from db. Processing finished
        break;
    end
    fprintf(1, 'run_airxbcal_batch: processing day %d, year %d\n', ...
            iDoy, iYear)

    create_airxbcal_rtp(iDoy, iYear);

    close_job_table_entry(iTaskID, iEntryID);

end

end