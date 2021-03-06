function [mdr] = read_eps_mdr825(fid, nbytes);

% function [mdr] = read_eps_mdr825(fid, nbytes);
%
% Read an EPS (Eumetsat Polar System) binary file MDR
% record and return a subset of the fields. Many of
% the fields are resized and/or renamed to better
% match "readl1c_binary_all.m".
% Name 'mdr-1c',class 8, subclass 2, version 5
%
% Input:
%    fid - [1 x 1] input file I/O number
%    nbytes - [1 x 1] total number of bytes in record
%
% Output:
%    mdr - [structure] contains the following fields:
%       GEPSDatIasi [1 x 30] converted to tai2000
%       GEPS_CCD [1 x 30] uint8
%       GEPS_SP [1 x 30] int32
%       GIrcImage [4096 x 30] uint16
%       GQisFlagQual [3 x 4 x 30] uint8 (resized v4)
%       GQisFlagQualDetailed [4 x 30] uint16 (no v4)
%       GGeoSondLoc [2 x 4 x 30] converted to degrees
%       GGeoSondAnglesMetop [2 x 4 x 30] converted to degrees
%       GGeoSondAnglesSun [2 x 4 x 30] converted to degrees
%       GGeoISSLoc [2 x 25 x 30] int32 degrees*1E+6
%       EARTH_SATELLITE_DISTANCE [1 x 30] repeated from [1 x 1]
%       GS1xSpect [8700 x 4 x 30] int16 from GS1cSpect
%       GEUMAvhrr1BCldFrac [4 x 30] uint8 percent (no v4)
%       GEUMAvhrr1BLandFrac [4 x 30] uint8 percent (no v4)
%       GEUMAvhrr1BQual [4 x 30] uint8 bit fields (no v4)
%       IASI_FOV [4 x 30] created from index
%    note: Fields are doubles except where noted otherwise.
%    The last dimension of all output fields is always 30.
%    WARNING! Imager and IASI radiances are unscaled; you
%    must use giadr_sf to convert to radiance units.
%

% Created: 22 September 2010, Scott Hannon
% Update: 29 Sep 2011, S.Hannon - add GQisFlagQualDetailed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Number of bytes in generic record header
grhbytes = 20;

% Seconds per day
secperday = 3600*24;

mdr = [];

% Read MDR record data
bytedata = fread(fid,[1,nbytes],'*uint8');

% Pull out data for desired fields

% GEPSDatIasi => Time2000
offset = 9122;
fieldsize = 180; % 2+4 bytes each x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = bytedata(istart:iend);
mdr.Time2000 = zeros(1,30);
for ii=1:30
   ind = ((ii-1)*6) + (1:6);
   day = swapbytes(typecast(junk(ind(1:2)),'uint16'));
   msec = swapbytes(typecast(junk(ind(3:6)),'uint32'));
   mdr.Time2000(ii) = double(day)*secperday + double(msec)*1E-3;
end

% GEPS_CCD => Scan_Direction
offset=9350;
fieldsize=30; % 1 byte each x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
mdr.GEPS_CCD = bytedata(istart:iend);

% GEPS_SP => AMSU_FOV
offset=9380;
fieldsize=120; % 4 btyes each x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
mdr.GEPS_SP = swapbytes(typecast(bytedata(istart:iend),'int32'));

% GIrcImage => IASI_Image
offset=9500;
fieldsize=245760; % 2 bytes each x64x64x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'uint16'));
mdr.GIrcImage = reshape(junk,4096,30);

% GQisFlagQual (note: different dimensions in version 4)
offset=255260;
fieldsize=360; % 1 byte each x3x4x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
mdr.GQisFlagQual = reshape(bytedata(istart:iend),3,4,30);

% GQisFlagQualDetailed (note: does not exist in version 4)
offset=255620;
fieldsize=240; % 2 byte2 each 4x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'uint16'));
% Note: last 3 bits not used so uint16 value < 4096
mdr.GQisFlagQualDetailed = reshape(junk,4,30);

% GGeoSondLoc
offset=255893;
fieldsize=960; % 4 bytes each x2x4x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'int32'));
mdr.GGeoSondLoc = double(reshape(junk,2,4,30))*1E-6;

% GGeoSondAnglesMetop => Satellite_Azimuth & Satellite_Zenith
offset=256853;
fieldsize=960; % 4 bytes each x2x4x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'int32'));
mdr.GGeoSondAnglesMetop = double(reshape(junk,2,4,30))*1E-6;

% GGeoSondAnglesSun
offset=263813;
fieldsize=960; % 4 bytes each x2x4x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'int32'));
mdr.GGeoSondAnglesSun = double(reshape(junk,2,4,30))*1E-6;

% GGeoIISLoc => ImageLat & ImageLon
offset=270773;
fieldsize=6000; % 4 bytes each x2x25x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'int32'));
mdr.GGeoIISLoc = reshape(junk,2,25,30);

% EARTH_SATELLITE_DISTANCE => Satellite_Height
offset=276773;
fieldsize=4; % 4 bytes each x1
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'uint32'));
mdr.EARTH_SATELLITE_DISTANCE = double(junk)*ones(1,30);

% GS1cSpect
offset=276790;
fieldsize=2088000; % 2 bytes each x8700x4x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
junk = swapbytes(typecast(bytedata(istart:iend),'int16'));
mdr.GS1cSpect = reshape(junk,8700,4,30);

% GEUMAvhrr1BCldFrac (note: does not exist in version 4)
offset=2728548;
fieldsize=120; % 1 byte each x4x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
mdr.GEUMAvhrr1BCldFrac = reshape(bytedata(istart:iend),4,30);

% GEUMAvhrr1BLandFrac (note: does not exist in version 4)
offset=2728668;
fieldsize=120; % 1 byte each x4x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
mdr.GEUMAvhrr1BLandFrac = reshape(bytedata(istart:iend),4,30);

% GEUMAvhrr1BQual (note: does not exist in version 4)
offset=2728788;
fieldsize=120; % 1 byte each x4x30
istart = offset + 1 - grhbytes;
iend = istart + fieldsize - 1;
mdr.GEUMAvhrr1BQual = reshape(bytedata(istart:iend),4,30);


% IASI_FOV
mdr.IASI_FOV = (1:4)'*ones(1,30); %'

%%% end of function %%%
