function run_climcaps_cc_fix_rtp(driverfile)

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

% file_list contains lines like
% /umbc/xfs3/strow/asl/CLIMCAPS_SNDR_SNPP_CCR/FSR/2018/07/22
[status, infilepath] = system(sprintf('sed -n "%dp" %s | tr -d "\n"', ...
                                  slurmindex, driverfile ));

if strcmp(infilepath, '')
    return;
end

climcaps_cc_fix_rtp(infilepath)

