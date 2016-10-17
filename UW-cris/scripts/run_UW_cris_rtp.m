function run_UW_cris_rtp()

% granule names look like
% SNDR.SNPP.CRIS.20160120T2312.m06.g233.L1B_NSR.std.v01_00_00.W.160311164050.nc
%
% and source from
% /home/strow/Work/Cris/Nasa/L1b/beta3

infilepath = '/home/strow/Work/Cris/Nasa/L1b/beta3';

outfilepath = ['/home/sbuczko1/testoutput/rtp_cris_UW_lowres/clear/' ...
               '2016'];

files = dir(fullfile(infilepath, '*.nc'));
numfiles = length(files);

fprintf(1, '> Processing %d netcdf granule files\n', numfiles);

for i=1:numfiles
    fprintf(1, '>> Processing granule %d\n', i);
    % build input file path and name
    fnCrisInput = fullfile(infilepath, files(i).name);

    % build output file path and name
    C = strsplit(files(i).name, '.');
    % make output filename like:
    % uwcris_20160120T2312_g233_clear.rtp
    sName = ['uwcris_' C{4} '_' C{6} '_clear.rtp'];
    fnCrisOutput = fullfile(outfilepath, sName);
    
    % process netcdf file to rtp
    try
        create_uwcris_lowres_rtp(fnCrisInput, fnCrisOutput);
    catch
        fprintf(2, '>>> Error converting granule: %s  :: skipping\n', ...
                files(i).name);
        continue;
        end
end


fprintf(1, '> Done\n');
