function run_UW_cris_rtp(cfg)

% granule names look like
% SNDR.SNPP.CRIS.20160120T2312.m06.g233.L1B_NSR.std.v01_00_00.W.160311164050.nc
%
% and source from
% /home/strow/Work/Cris/Nasa/L1b/beta3

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

% offset slurmindex to bypass MaxArraySize boundary
%slurmindex = slurmindex + 19999

chunk = cfg.chunk;
for i = 1:chunk
dayindex = (slurmindex*chunk) + i;
fprintf(1, '>>> chunk %d  dayindex %d\n', 1, dayindex);

% File ~/cris-files-process.txt is a list of filepaths to the input
% files or this processing. For the initial runs, this was
% generated by a call to 'ls' while sitting in the directory
% /asl/data/cris/ccast/sdr60_hr/2015: 
%    ls -d1 $PWD/{048,049,050}/*.mat >> ~/cris-files-process.txt
%
% cris-files-process.txt, then, contains lines like:
%    /asl/data/cris/ccast/sdr60_hr/2015/048/SDR_d20150217_t1126169.mat
[status, infilepath] = system(sprintf('sed -n "%dp" %s | tr -d "\n"', ...
                                  dayindex, 'SNPP_file.list'));

if strcmp(infilepath, '')
    return;
end

files = dir(fullfile(infilepath, '*.nc'));
numfiles = length(files);

fprintf(1, '> Processing %d netcdf granule files\n', numfiles);

for i=1:numfiles
    fprintf(1, '>> Processing granule %d\n', i);
    % build input file path and name
    fnCrisInput = fullfile(infilepath, files(i).name);

    % process netcdf file to rtp
    [h,ha,p,pa] = create_rtp_cris_netcdf(fnCrisInput);

    % filter out desired FOVs/scan angles
    fprintf(1, '>>> Running get_equal_area_sub_indices for random selection... \n');
    fors = [1:30];

    nadir = ismember(p.xtrack,fors);

    % rtp has a 2GB limit so we have to scale number of kept FOVs
    % to stay within that as an absolute limit. Further, we
    % currently restrict obs count in random to ~20k to match
    % historical AIRXBCAL processing
    limit = 20000;  % number of obs to keep
    nswath = 45;  % length of ccast granules
    ngrans = 240;  % number of granules per day
    nfovs = 9;  % number of FOVs per FOR
    maxobs = nswath * length(fors) * nfovs * ngrans;
    scale = (limit/maxobs)*1.6; % preserves ~65k obs/day 
    randoms = get_equal_area_sub_indices(p.rlat, scale);
    nrinds = find(nadir & randoms);
    if length(nrinds) == 0
        return
    end
    p2 = rtp_sub_prof(p, nrinds);
    clear p
    fprintf(1, '>>> Found %d obs after random selection\n', length(p2.rtime));


    if 1 == i
        head = h;
        hattr = ha;
        prof = p2;
        pattr = pa;
    else
        prof = rtp_cat_prof(prof, p2);
    
    end

end

% build output file path and name
C = strsplit(files(1).name, '.');
% SNDR.SNPP.CRIS.20170903T1142.m06.g118.L1B.std.v02_05.G.180615223853.nc
D = extractBetween(C{4},1,8);
sName = ['SNDR.SNPP.CRIS_' D{1} '_random.rtp'];

C = strsplit(infilepath, '/');
outfilepath = fullfile(cfg.outputdir, 'random', C{end-1}, C{end});
if exist(outfilepath) == 0
    mkdir(outfilepath);
end
fnOutFile = fullfile(outfilepath, sName);
fprintf(1, '>> Writing output rtp to: %s\n', fnOutFile)
rtpwrite(fnOutFile, head, hattr, prof, pattr);

end % end loop over chunk
fprintf(1, '> Done\n');
