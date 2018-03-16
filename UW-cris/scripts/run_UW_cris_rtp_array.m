function run_UW_cris_rtp_array()

% granule names look like
% SNDR.SNPP.CRIS.20160120T2312.m06.g233.L1B_NSR.std.v01_00_00.W.160311164050.nc
%
% and source from
% /home/strow/Work/Cris/Nasa/L1b/beta3

infilepath = '/asl/s1/strow/L1b_J1/v2.1b4_a2_mod_20180131/2018/021';

outfilepath = ['/asl/rtp/rtp_cris_UW_hires/clear/' ...
               '2018/021'];
if exist(outfilepath) == 0
    mkdir(outfilepath);
end

files = dir(fullfile(infilepath, '*.nc'));

fileindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

thisfile = files(fileindex).name;

fprintf(1, '> Processing netcdf granule file %s\n', thisfile);

% build input file path and name
fnCrisInput = fullfile(infilepath, thisfile);

% build output file path and name
C = strsplit(thisfile, '.');
% make output filename like:
% uwcris_20160120T2312_g233_clear.rtp
sName = ['uwcris_ecmwf_' C{4} '_' C{6} '_clear.rtp'];
fnCrisOutput = fullfile(outfilepath, sName);

% process netcdf file to rtp
try
    [h,ha,p,pa] = create_uwcris_lowres_rtp(fnCrisInput);
catch
    fprintf(2, '>>> Error converting granule: %s  :: skipping\n', ...
            files(i).name);
end

rtpwrite(fnCrisOutput, h,ha,p,pa);

fprintf(1, '> Done\n');
