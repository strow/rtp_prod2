function run_uw_nc_rtp(cfg)

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

chunk = cfg.chunk;
for i = 1:chunk
dayindex = (slurmindex*chunk) + i;
fprintf(1, '>>> chunk %d  dayindex %d\n', 1, dayindex);

% file_list contains lines like
%% /asl/cris/nasa_l1b/j02/2023/043/SNDR.J2.CRIS.20230212T0000.m06.g001.L1B.std.v4_0-r20221220_212541.W.230212145648.nc
[status, infilepath] = system(sprintf('sed -n "%dp" %s | tr -d "\n"', ...
                                  dayindex, cfg.file_list));

if strcmp(infilepath, '')
    return;
end
    % process netcdf file to rtp
    [h,ha,p,pa] = create_rtp_cris_netcdf(infilepath,cfg);

% build output file path and name
%% SNDR.J2.CRIS.20230212T2236.m06.g227.L1B.std.v4_0-r20221220_212541.W.230213045714.nc
[path,name,ext] = fileparts(infilepath);
C = strsplit(name, '.');
D = extractBetween(C{4},1,8);
dt = datetime(D{1}, 'InputFormat', 'yyyyMMdd');
dt.Format='DDD';   % convert to day of year
sdt = char(dt);  % make day of year string

outfilepath = fullfile(cfg.outputdir, 'allfov', C{4}(1:4), sdt);
if exist(outfilepath) == 0
    mkdir(outfilepath);
end

sName = sprintf('%s.rtp', name);
fnOutFile = fullfile(outfilepath, sName);
fprintf(1, '>> Writing output rtp to: %s\n', fnOutFile)
rtpwrite(fnOutFile, h,ha,p,pa);

end % end loop over chunk
fprintf(1, '> Done\n');
