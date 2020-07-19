function [grh] = read_eps_grh(fid);

% function [grh] = read_eps_grh(fid);
%
% Read an EPS (Eumetsat Polar System) binary file 20 byte generic
% record header (GRH) from the current position in the input file.
%
% Input:
%    fid - [1 x 1] input file I/O number
%
% Output:
%    grh - [structure] contains the following seven [1 x 1] fields:
%       RECORD_CLASS: code number with values:
%           0=reserved
%           1=MPHR (main product header record),
%           2=SPHR (secondary product header record)
%           3=IPR (internal pointer record)
%           4=GEADR (global external auxillary data record)
%           5=GIADR (global internal auxillary data record)
%           6=VEADR (variable external auxillary data record)
%           7=VIADR (variable internal auxillary data record)
%           8=MDR (measurement data record)
%       INSTRUMENT_GROUP: code number with values:
%           0=generic; 1=AMSU-A; 2=ASCAT; 3=ATOVS instruments (AVHRR/3,
%           HIRS/4, AMSU-A, MHS); 4=AVHRR/3; 5=GOME; 6=GRAS; 7=HIRS/4;
%           8=IASI (except L2); 9=MHS; 10=SEM; 11=ADCS; 12=SBUV;
%           13=dummy; 14=archive; 15=IASI_L2
%       RECORD_SUBCLASS: values vary with instrument.
%       RECORD_SUBCLASS_VERSION: version number of subclass
%       RECORD_SIZE: total size in bytes INCLUDING 20 byte GRH
%       RECORD_START_TIME: for class MDR this is the first sensing time;
%          for all other class it is the start time of the first MDR
%       RECORD_STOP_TIME: for class MDR this is the last sensing time;
%          for all other class it is the stop time of the last MDR
%       note: time has been converted from day+msec to TAI2000. All
%       seven grh fields are double precision.
%

% Created: 22 September 2010, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

secperday = 3600*24; % seconds per day

% Read 20 bytes
databytes = fread(fid,20,'*uint8');

grh.RECORD_CLASS = double(databytes(1));
grh.INSTRUMENT_GROUP = double(databytes(2));
grh.RECORD_SUBCLASS = double(databytes(3));
grh.RECORD_SUBCLASS_VERSION = double(databytes(4));

junk = databytes(5:8);
recsize = swapbytes(typecast(junk,'uint32'));
grh.RECORD_SIZE = double(recsize);

junk = databytes(9:10);
day = swapbytes(typecast(junk,'uint16'));
junk = databytes(11:14);
msec = swapbytes(typecast(junk,'uint32'));
grh.RECORD_START_TIME=double(day)*secperday + double(msec)*1E-3;

junk = databytes(15:16);
day = swapbytes(typecast(junk,'uint16'));
junk = databytes(17:20);
msec = swapbytes(typecast(junk,'uint32'));
grh.RECORD_STOP_TIME=double(day)*secperday + double(msec)*1E-3;

%%% end of function %%%
