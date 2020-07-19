function [giadr_sf] = read_eps_giadr512(fid, nbytes);

% function [giadr_sf] = read_eps_giadr512(fid, nbytes);
%
% Read an EPS (Eumetsat Polar System) binary file GIADR
% scalefactors record and return a subset of the fields.
% Name 'giadr-scalefactors',class 5, subclass 1, version 2
%
% Input:
%    fid - [1 x 1] input file I/O number
%    nbytes - [1 x 1] total number of bytes in record
%
% Output:
%    giadr_sf - [structure] contains the following five fields:
%       IDefScaleSondNbScale - [1 x 1] number of bands
%       IDefScaleSondNsfirst - 1 x 10] start channel index for band
%       IDefScaleSondNslast - [1 x 10] end channel index for band
%       IDefScaleSondScaleFactor - [1 x 10] scale factor {power of 10}
%       IDefScaleIISScaleFactor - Imager scale factor {power of 10}
%    note: All fields are returned as doubles.
%

% Created: 22 September 2010, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


grhbytes = 20;

giadr_sf = [];

% Read GIADR record data
bytedata = fread(fid,[1,nbytes],'*uint8');

% Pull out data for desired fields

% IDefScaleSondNbScale
offset = 20;
fieldsize = 2;
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'uint16'));
giadr_sf.IDefScaleSondNbScale = double(junk);

% IDefScaleSondNsfist
offset=22;
fieldsize=20;
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'uint16'));
giadr_sf.IDefScaleSondNsfirst = double(junk);

% IDefScaleSondNslast
offset=42;
fieldsize=20;
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'uint16'));
giadr_sf.IDefScaleSondNslast = double(junk);

% IDefScaleSondScaleFactor
offset=62;
fieldsize=20;
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'uint16'));
giadr_sf.IDefScaleSondScaleFactor = double(junk);

% IDefScaleIISScaleFactor
offset=82;
fieldsize=2;
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'uint16'));
giadr_sf.IDefScaleIISScaleFactor = double(junk);

%%% end of function %%%
