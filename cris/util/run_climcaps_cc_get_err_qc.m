function run_climcaps_cc_get_err_qc(driverfile)

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

% file_list contains lines like
% /umbc/xfs3/strow/asl/CLIMCAPS_SNDR_SNPP_CCR/FSR/2018/07/22
[status, infilepath] = system(sprintf('sed -n "%dp" %s | tr -d "\n"', ...
                                  slurmindex, driverfile ));

if strcmp(infilepath, '')
    return;
end

% parse line from driver file to retrieve year, month, day
C = strsplit(infilepath, '/');
year = str2num(C{8});
month = str2num(C{9});
day = str2num(C{10});

climcaps_cc_get_err_qc(year, month, day)

