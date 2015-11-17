function [data] = readl1c_epsflip_all(fname);

% function [data] = readl1c_epsflip_all(fname);
%
% Read a IASI level 1C EPS binary data file and return a structure of data.
% This "flip" version flips the natural index ordering to match the
% output produced by the "readl1c_binary_all.m" beat reader.
%
% Input:
%    fname = {string} name of binary data file to read
%
% Output:
%    data = {structure} IASI data structure with the following fields:
%       eps_name              {string} fname without dirs
%       instrument_id         {string} instrument ID
%       spacecraft_id         {string} spacecraft ID
%       process_version       [1 x 1] processing <major>.<minor> version
%       state_vector_time     [1 x 1] orbit start time
%       Time2000              [nax x 4] seconds since 0z 1 January 2000
%       Latitude              [nax x 4] latitude
%       Longitude             [nax x 4] longitude
%       Satellite_Height      [nax x 4] satellite height
%       Satellite_Zenith      [nax x 4] satellite zenith angle
%       Satellite_Azimuth     [nax x 4] satellite azimuth angle
%       Solar_Zenith          [nax x 4] solar zenith angle
%       Solar_Azimuth         [nax x 4] solar azimuth angle
%       Scan_Direction        [nax x 4] scan direction
%       Scan_Line             [nax x 4] along-track index 1 to Na, Na<=23
%       AMSU_FOV              [nax x 4] cross-track index 1 to 30, 0=bad
%       IASI_FOV              [nax x 4] pixel number 1 to 4
%       GQisFlagQual          [nax x 4] OK=0, bad=1
%       Avhrr1BLandFrac       [nax x 4] AVHRR determined land fraction
%       Avhrr1BCldFrac        [nax x 4] AVHRR determined cloud fraction
%       Avhrr1BQual           [nax x 4] AVHRR analysis quality flag
%       ImageLat              [nax x 25] imager 5x5 subgrib latitude
%       ImageLon              [nax x 25] imager 5x5 subgrib longitude
%       IASI_Image            [nax x 4096] imager radiance
%       IASI_Radiances        [nax x 4 x 8461] IASI radiance
% Note: all non-string fields are doubles.
%

% Created: 23 September 2010, Scott Hannon
% Update: 10 Jan 2011, S.Hannon - bug fix for "totalsize" when file is gziped
%   for aslutil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Radiance units conversion factor for imager and IASI data to convert
% from W/m^2 per steradian per m^-1 to mW/m^2 per steradian per cm^-1
rconvpower = 5;

mean_earth_radius = 6371229; % meters

grhbytes=20;

tname = mktemp();
if strcmp(fname(end-2:end),'.gz')
  %disp(['/asl/opt/bin/zcat ' fname ' > ' tname]);
  system(['/bin/zcat ' fname ' > ' tname]);
  fid = fopen(tname,'r');
  d = dir(tname);
else
  %disp(['raw reading ' fname]);
  fid = fopen(fname,'r');
  d = dir(fname);
end
totalsize = d.bytes;
name = d.name;

nbytes_count = 0;
imdr = 0;
nmdr = 0;

% Loop over the records
while (nbytes_count < totalsize)

   % Read current record header
   grh = read_eps_grh(fid);
   nbytes_count = nbytes_count + grhbytes;
   nbytes = grh.RECORD_SIZE - grhbytes;
   %
   CSCV=[int2str(grh.RECORD_CLASS) ',' int2str(grh.RECORD_SUBCLASS) ',' ...
      int2str(grh.RECORD_SUBCLASS_VERSION)];

   switch CSCV
      case '1,0,2'
         mphr = read_eps_mphr102(fid,nbytes);
         nbytes_count = nbytes_count + nbytes;
         nmdr = double(mphr.TOTAL_MDR);
         nax = nmdr*30;
         %
      case '5,1,2'
         % read giadr_scalefactors record
%         disp('reading giadr_scalefactors record');
         giadr_sf = read_eps_giadr512(fid,nbytes);
         nbytes_count = nbytes_count + nbytes;
         %
      case '8,2,4'
         if (nmdr == 0)
	   error('reading a mdr before mphr tells me TOTAL_MDR')
         end
         imdr = imdr + 1;
%         disp(['reading mdr record for scanline ' int2str(imdr)])
         mdr1 = read_eps_mdr824(fid,nbytes);
         mdr1.Scan_Line = imdr*ones(4,30); % scanline index
         nbytes_count = nbytes_count + nbytes;
         %
         % Concatenate mdr data for scanlines
         if (imdr == 1)
            % Declare output array
            mdr = declare_mdr(mdr1,nmdr);
         end
         % Copy current mdr to output array
         ind = ((imdr-1)*30) + (1:30);
         mdr = load_mdr(mdr1,ind,mdr);
         %
      case '8,2,5'
         if (nmdr == 0)
	   error('reading a mdr before mphr tells me TOTAL_MDR')
         end
         imdr = imdr + 1;
%         disp(['reading mdr record for scanline ' int2str(imdr)])
         mdr1 = read_eps_mdr825(fid,nbytes);
         mdr1.Scan_Line = imdr*ones(4,30); % scanline index
         nbytes_count = nbytes_count + nbytes;
         %
         % Concatenate mdr data for scanlines
         if (imdr == 1)
            % Declare output array
            mdr = declare_mdr(mdr1,nmdr);
         end
         % Copy current mdr to output array
         ind = ((imdr-1)*30) + (1:30);
         mdr = load_mdr(mdr1,ind,mdr);
         %
      otherwise
%         disp(['skipping record ' CSCV])
         junk=fread(fid,nbytes,'*uint8');
         nbytes_count = nbytes_count + nbytes;
         %
   end

end
clear junk ind mdr1 grh imdr CSCV nbytes nbytes_count
%
fclose(fid);

unlink(tname)

% Create output "data" structure
data.eps_name = name;
data.spacecraft_id = mphr.SPACECRAFT_ID;
data.instrument_id = mphr.INSTRUMENT_ID;
data.process_version = mphr.PROCESSOR_MAJOR_VERSION + ...
   mphr.PROCESSOR_MINOR_VERSION*0.1;
data.state_vector_time = mphr.STATE_VECTOR_TIME;
data.Time2000 = (ones(4,1)*mdr.Time2000)'; %'
data.Latitude = squeeze( mdr.GGeoSondLoc(2,:,:) )'; %'
data.Longitude = squeeze( mdr.GGeoSondLoc(1,:,:) )'; %'
data.Satellite_Height = (ones(4,1)*(mdr.EARTH_SATELLITE_DISTANCE - ...
   mean_earth_radius))'; %'
data.Satellite_Zenith = squeeze( mdr.GGeoSondAnglesMetop(1,:,:) )'; %'
data.Satellite_Azimuth = squeeze( mdr.GGeoSondAnglesMetop(2,:,:) )'; %'
data.Solar_Zenith = squeeze( mdr.GGeoSondAnglesSun(1,:,:) )'; %'
data.Solar_Azimuth = squeeze( mdr.GGeoSondAnglesSun(2,:,:) )'; %'
data.Scan_Direction = (ones(4,1)*double(mdr.GEPS_CCD))'; %'
data.Scan_Line = mdr.Scan_Line'; %'
data.AMSU_FOV = (ones(4,1)*double(mdr.GEPS_SP))'; %'
data.IASI_FOV = mdr.IASI_FOV'; %'
d = size(mdr.GQisFlagQual);
if (length(d) == 3)
   % Change 3 booleans to 3 bit flags
   junk = double(mdr.GQisFlagQual);
   data.GQisFlagQual = (squeeze(junk(3,:,:))*4 + squeeze(junk(2,:,:))*2 + ...
      squeeze(junk(1,:,:)))'; %'
else
   data.GQisFlagQual = double(mdr.GQisFlagQual)'; %'
end
%
if (isfield(mdr,'GEUMAvhrr1BLandFrac'))
   data.Avhrr1BLandFrac = double(mdr.GEUMAvhrr1BLandFrac)'/100; %'
end
if (isfield(mdr,'GEUMAvhrr1BCldFrac'))
   data.Avhrr1BCldFrac = double(mdr.GEUMAvhrr1BCldFrac)'/100; %'
end
if (isfield(mdr,'GEUMAvhrr1BQual'))
   data.Avhrr1BQual = double(mdr.GEUMAvhrr1BQual)'; %'
end
%
data.ImageLat = double(squeeze(mdr.GGeoIISLoc(2,:,:)))'*1E-6; %'
data.ImageLon = double(squeeze(mdr.GGeoIISLoc(1,:,:)))'*1E-6; %'


% Apply giasr_sf to Imager
power = rconvpower - giadr_sf.IDefScaleIISScaleFactor;
rscale = 1;
if (abs(power) > 0)
  eval(['rscale = 1E' int2str(power) ';'])
end
junk = reshape(double(mdr.GIrcImage)*rscale,64,64,nax);
junk = permute(junk,[3,2,1]);
data.IASI_Image = reshape(junk,nax,4096);


% Apply giasr_sf to IASI
% IASI scale factors do not start at 1, but at this value:
offset = giadr_sf.IDefScaleSondNsfirst(1); % 2581=645.0 cm^-1
junk = permute( mdr.GS1cSpect,[3,2,1] );
junk = junk(:,:,1:8461);
data.IASI_Radiances = double(junk);
%
for isect = 1:giadr_sf.IDefScaleSondNbScale
   ibegin = giadr_sf.IDefScaleSondNsfirst(isect);
   iend = giadr_sf.IDefScaleSondNslast(isect);
   power = rconvpower - giadr_sf.IDefScaleSondScaleFactor(isect);
   if (abs(power) > 0)
      eval(['rscale = 1E' int2str(power) ';'])
      ind = (ibegin-offset+1):(iend-offset+1);
      data.IASI_Radiances(:,:,ind)=data.IASI_Radiances(:,:,ind)*rscale;
   end
end

%%% end of program %%%
