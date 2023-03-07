function run_climcaps_rtp(cfg)

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

chunk = cfg.chunk;
for i = 1:chunk
dayindex = (slurmindex*chunk) + i;
fprintf(1, '>>> chunk %d  dayindex %d\n', 1, dayindex);

% file_list contains lines like
%% /asl/xfs3/CLIMCAPS_SNDR_SNPP_CCR/NSR/2013/01/14  == infilepath
[status, infilepath] = system(sprintf('sed -n "%dp" %s | tr -d "\n"', ...
                                  dayindex, cfg.file_list));

if strcmp(infilepath, '')
    return;
end
    % process netcdf file to rtp
    [h,ha,p,pa] = create_rtp_climcaps(infilepath,cfg);

% build output file path and name
files = dir(sprintf('%s/*.nc',infilepath));
C = strsplit(files(1).name, '.');
%% SNDR.SNPP.CRIMSS.20130702T1042.m06.g108.L2_CLIMCAPS_CCR_NSR.std.v01_33_00.J.190411171021.nc
D = extractBetween(C{4},1,8);
sName = ['SNDR.SNPP.CRIMSS_' D{1} '_random.rtp'];
dt = datetime(D{1}, 'InputFormat', 'yyyyMMdd');
dt.Format='DDD';   % convert to day of year
sdt = char(dt);  % make day of year string
C = strsplit(infilepath, '/');
outfilepath = fullfile(cfg.outputdir, 'random', C{end-2}, sdt);
if exist(outfilepath) == 0
    mkdir(outfilepath);
end
fnOutFile = fullfile(outfilepath, sName);
fprintf(1, '>> Writing output rtp to: %s\n', fnOutFile)
rtpwrite(fnOutFile, h,ha,p,pa);

end % end loop over chunk
fprintf(1, '> Done\n');
