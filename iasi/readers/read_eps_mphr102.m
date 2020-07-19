function [mphr] = read_eps_mphr102(fid, nbytes);

% function [mphr] = read_eps_mphr102(fid, nbytes);
%
% Read an EPS (Eumetsat Polar System) binary file MPHR record
% and return a subset of the fields.
% Name 'mphr', class 1, subclass 0, version 2 
%
% Input:
%    fid - [1 x 1] input file I/O number
%    nbytes - [1 x 1] total number of bytes in record
%
% Output:
%    mphr - [structure] contains the following 17 fields:
%       INSTRUMENT_ID - [string]
%       PRODUCT_TYPE  - [string]
%       PRODUCT_LEVEL - [string]
%       SPACECRAFT_ID - [string]
%       PROCESSOR_MAJOR_VERSION
%       PROCESSOR_MINOR_VERSION
%       STATE_VECTOR_TIME
%       SENSING_START
%       SENSING_END
%       SUBSAT_LATITUDE_START
%       SUBSAT_LONGITUDE_START
%       SUBSAT_LATITUDE_END
%       SUBSAT_LONGITUDE_END
%       EARTH_SUN_DISTANCE_RATIO: dummy value?
%       TOTAL_RECORDS
%       TOTAL_MPHR
%       TOTAL_SPHR
%       TOTAL_IPR
%       TOTAL_GEADR
%       TOTAL_GIADR
%       TOTAL_VEADR
%       TOTAL_VIADR
%       TOTAL_MDR
%    note: time has been converted from YYYYMMDDHHmmssxxxZ to TAI2000. All
%    non-string fields are returned as doubles.
%

% Created: 22 September 2010, Scott Hannon
% Update: 10 January 2011, S.Hannon add SENSING_START and END and
%    SUBSAT_LATITUDE_START and END and LONGITUDE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


grhbytes = 20;

mphr = [];

% Read MPHR record data
bytedata = fread(fid,[1,nbytes],'*char');

% Pull out data for desired fields
% Note: all fields are strings, and the first 33 bytes are
% the variable name, blanks, and a equal sign.

% INSTRUMENT_ID: offset=520, fieldsize=37 {4+33}
istart=520 + 33 - grhbytes;
iend = istart + 4 - 1;
mphr.INSTRUMENT_ID = char(bytedata(istart:iend));

% PRODUCT_TYPE: offset=593, fieldsize=36 {3+33}
istart=593 + 33 - grhbytes;
iend = istart + 3 - 1;
mphr.PRODUCT_TYPE = char(bytedata(istart:iend));

% PROCESSING_LEVEL: offset=629, fieldsize=35 {2+33}
istart=629 + 33 - grhbytes;
iend = istart + 2 - 1;
mphr.PROCESSING_LEVEL = char(bytedata(istart:iend));

% SPACECRAFT_ID: offset=664, fieldsize=36 {3+33}
istart=664 + 33 - grhbytes;
iend = istart + 3 - 1;
mphr.SPACECRAFT_ID = char(bytedata(istart:iend));

% SENSING_START: offset=700, fieldsize=48 {15+33}
istart=700 + 33 - grhbytes;
iend = istart + 15 - 1;
junk = bytedata(istart:iend); %YYYYMMDDHHmmssZ
year = str2num(junk(1:4));
month = str2num(junk(5:6));
day = str2num(junk(7:8));
dhour = str2num(junk(9:10)) + str2num(junk(11:12))/60 + ...
   str2num(junk(13:14))/3600;
mphr.SENSING_START = utc2tai2000(year,month,day,dhour);

% SENSING_END: offset=748, fieldsize=48 {15+33}
istart=748 + 33 - grhbytes;
iend = istart + 15 - 1;
junk = bytedata(istart:iend); %YYYYMMDDHHmmssZ
year = str2num(junk(1:4));
month = str2num(junk(5:6));
day = str2num(junk(7:8));
dhour = str2num(junk(9:10)) + str2num(junk(11:12))/60 + ...
   str2num(junk(13:14))/3600;
mphr.SENSING_END = utc2tai2000(year,month,day,dhour);

% PROCESSOR_MAJOR_VERSION: offset=929, fieldsize=38 {5+33}
istart=929 + 33 - grhbytes;
iend = istart + 5 - 1;
mphr.PROCESSOR_MAJOR_VERSION = str2num(bytedata(istart:iend));

% PROCESSOR_MINOR_VERSION: offset=1043, fieldsize=38 {5+33}
istart=1043 + 33 - grhbytes;
iend = istart + 5 - 1;
mphr.PROCESSOR_MINOR_VERSION = str2num(bytedata(istart:iend));

% STATE_VECTOR_TIME: offset=1497, fieldsize=51 {18+33}
istart=1497 + 33 - grhbytes;
iend = istart + 18 - 1;
junk = bytedata(istart:iend); %YYYYMMDDHHmmssxxxZ
year = str2num(junk(1:4));
month = str2num(junk(5:6));
day = str2num(junk(7:8));
dhour = str2num(junk(9:10)) + str2num(junk(11:12))/60 + str2num(junk(13:14))/3600 ...
   + str2num(junk(15:17))/3600000;
mphr.STATE_VECTOR_TIME = utc2tai2000(year,month,day,dhour);

% EARTH_SUN_DISTANCE_RATIO: offset=2076, fieldsize=44 {11+33}
istart=2076 + 33 - grhbytes;
iend = istart + 11 - 1;
mphr.EARTH_SUN_DISTANCE_RATIO = str2num(bytedata(istart:iend));

% SUBSAT_LATITUDE_START: offset=2384, fieldsize=44 {11+33}
istart=2384 + 33 - grhbytes;
iend = istart + 11 - 1;
mphr.SUBSAT_LATITUDE_START = str2num(bytedata(istart:iend))*0.001;

% SUBSAT_LONGITUDE_START: offset=2428, fieldsize=44 {11+33}
istart=2428 + 33 - grhbytes;
iend = istart + 11 - 1;
mphr.SUBSAT_LONGITUDE_START = str2num(bytedata(istart:iend))*0.001;

% SUBSAT_LATITUDE_END: offset=2472, fieldsize=44 {11+33}
istart=2472 + 33 - grhbytes;
iend = istart + 11 - 1;
mphr.SUBSAT_LATITUDE_END = str2num(bytedata(istart:iend))*0.001;

% SUBSAT_LONGITUDE_END: offset=2516, fieldsize=44 {11+33}
istart=2516 + 33 - grhbytes;
iend = istart + 11 - 1;
mphr.SUBSAT_LONGITUDE_END = str2num(bytedata(istart:iend))*0.001;

% TOTAL_RECORDS: offset=2643, fieldsize=39 {6+33}
istart=2643 + 33 - grhbytes;
iend = istart + 6 - 1;
mphr.TOTAL_RECORDS = str2num(bytedata(istart:iend));

% TOTAL_MPHR (always 1): offset=2682, fieldsize=39 {6+33}
istart=2682 + 33 - grhbytes;
iend = istart + 6 - 1;
mphr.TOTAL_MPHR = str2num(bytedata(istart:iend));

% TOTAL_SPHR (0 or 1): offset=2721, fieldsize=39 {6+33}
istart=2721 + 33 - grhbytes;
iend = istart + 6 - 1;
mphr.TOTAL_SPHR = str2num(bytedata(istart:iend));

% TOTAL_IPR: offset=2760, fieldsize=39 {6+33}
istart=2760 + 33 - grhbytes;
iend = istart + 6 - 1;
mphr.TOTAL_IPR = str2num(bytedata(istart:iend));

% TOTAL_GEADR: offset=2799, fieldsize=39 {6+33}
istart=2799 + 33 - grhbytes;
iend = istart + 6 - 1;
mphr.TOTAL_GEADR = str2num(bytedata(istart:iend));

% TOTAL_GIADR: offset=2838, fieldsize=39 {6+33}
istart=2838 + 33 - grhbytes;
iend = istart + 6 - 1;
mphr.TOTAL_GIADR = str2num(bytedata(istart:iend));

% TOTAL_VEADR: offset=2877, fieldsize=39 {6+33}
istart=2877 + 33 - grhbytes;
iend = istart + 6 - 1;
mphr.TOTAL_VEADR = str2num(bytedata(istart:iend));

% TOTAL_VIADR: offset=2916, fieldsize=39 {6+33}
istart=2916 + 33 - grhbytes;
iend = istart + 6 - 1;
mphr.TOTAL_VIADR = str2num(bytedata(istart:iend));

% TOTAL_MDR: offset=2955, fieldsize=39 {6+33}
istart=2955 + 33 - grhbytes;
iend = istart + 6 - 1;
mphr.TOTAL_MDR = str2num(bytedata(istart:iend));

%%% end of function %%%
