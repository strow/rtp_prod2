function [prof, pattr] = readsdr_rtp(pdfile);

% function [prof, pattr] = readsdr_rtp(pdfile);
%
% Read a CrIS HDF5 SDR "Product_Data" file and matching "Geolocation"
% file and return a RTP profiles structure and attributes for a
% subset of the data.
%
% Input:
%    pdfile  : [string] name of CrIS HDF5 SDR "Product_Data" file
%    Note: the first 37 char of the Geolocation basename is assumed
%    to be the same as pdfile except "SCRIS_" prefix replaced by "GCRSO_".
%
% Output:
%    prof    : [structure] RTPv201 "profiles" structure
%    pattr   : [cell array] attribute strings
%

% Created: 20 January 2011, Scott Hannon
% Update: 01 Mar 2011, S.Hannon - bug fix for ifov
% Update: 09 Dec 2011, S.Hannon - add QAbits iudefs and robsqual; set
%    prof fields to appropriate RTP types
% Update: 15 Jan 2012, L. Strow - switched to readsdr_rawpd_all.m; used Geo 
%    file name from pd_file_a.N_GEO_Ref instead of string searching.  This
%    update on /asl/prod includes Scott's 09 Dec updates as well
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%addpath /asl/matlab/cris/readers
%addpath /asl/matlab/cris/utils

% Number of seconds between 0z 1 Jan 1958 and 0z 1 Jan 2000 (excluding
% leap seconds).
seconds1958to2000 = 15340 * 24 * 3600;

% Note: nchan* includes 2 guards at each end of each band
nchanLW = 717;
% $$$ nchanMW = 437;
% $$$ nchanSW = 163;
nchanMW = 869;
nchanSW = 637;
nchan = round(nchanLW + nchanMW + nchanSW); % exact integer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
if (nargin ~= 1)
   error('unexpected number of input arguments')
end

% Read the Product_Data file
[pd pd_file_a pd_aggr_a pd_sdr_a pd_gran0_a] = readsdr_rawpd_all(pdfile);

% Determine geofile from pdfile
[sdrdir,sdrname,sdrext] = fileparts(pdfile);

%if isfield(pd_file_a,'N_GEO_Ref')
%  geofile = fullfile(sdrdir,pd_file_a.N_GEO_Ref)
%else

% $$$   f = dir(regexprep(pdfile,{'sdr' 'SCRIS' '_c[0-9]+'},{'geo' 'GCRSO' '*'}));
% $$$   geodir = regexprep(sdrdir, {'sdr'},{'geo'});
  
  C = strsplit(sdrdir, '/');
  geodir = sprintf('/asl/cris/geo60_npp/%s/%s', C{8},C{9});
  geoname = [regexprep(sdrname,{'SCRIF' '_c[0-9]+'},{'GCRSO' '*'}) sdrext];
  f = dir(fullfile(geodir, geoname));

  if(numel(f)>1)
    fdates=[f.datenum];
    ifnewest=find(fdates==max(fdates));
    disp('Warning (readersdr_rtp.m): Found duplicated geo file names! Using the newest one');
    f=f(ifnewest);
  end

  geofile = fullfile(f.folder,f.name);

%end

if exist(geofile) ~= 2
   disp('Geo file does not exist - trying the original one.')
   geofile = pdfile;
end

% Create a structure of quality flag info
[qa] = cris_sdr_QAFlags(pd);
% Convert QA data to QAbits for each band and overall qual flag
[QAbitsLW,QAbitsMW,QAbitsSW,qual] = QA_to_bits(qa);
clear qa

% Read the Geolocation file
[geo] = readsdr_rawgeo(geofile);

%[geo2, agatt, attr4] = read_GCRSO(geofile)

%keyboard

% We have no means to check the match of pd and geo files but we
% can at least can check they have the same number of observations

% Create "prof" structure by subsetting data
prof = [];
%
if isfield(geo,'Latitude') & all(geo.Latitude < -900) & isfield(geo,'Longitude') & all(geo.Longitude < -900)
   
end
if (isfield(geo,'Latitude'))
   junk = geo.Latitude;
   s = size(junk);
   nobs = round(prod(s)); % exact integer
   prof.rlat = single( reshape(junk,1,nobs) );
else
   error('Missing required field Latitude')
end
%
if (isfield(geo,'Longitude'))
   junk = geo.Longitude;
   prof.rlon = single( reshape(junk,1,nobs) );
else
   error('Missing required field Longitude')
end
%
if (isfield(geo,'FORTime'))
   % Convert IET1958 microseconds to TAI2000
% $$$    junk = double(geo.FORTime)*1E-6 - seconds1958to2000; % [30 x 4*n]
   junk = iet2tai(double(geo.FORTime));
   s = size(junk);
   nx = round(prod(s)); % exact integer
   junk2 = reshape(junk,1,nx);
   prof.rtime = reshape(ones(9,1)*junk2,1,nobs);
else
   error('Missing required field FORTime')
end
%
if (isfield(geo,'SatelliteZenithAngle'))
   junk = geo.SatelliteZenithAngle;
   prof.satzen = single( reshape(junk,1,nobs) );
else
   error('Missing required field SatelliteZenithAngle')
end
%
if (isfield(geo,'SatelliteAzimuthAngle'))
   junk = geo.SatelliteAzimuthAngle;
   prof.satazi = single( reshape(junk,1,nobs) );
else
   error('Missing required field SatelliteAzimuthAngle')
end
%
if (isfield(geo,'SolarZenithAngle'))
   junk = geo.SolarZenithAngle;
   prof.solzen = single( reshape(junk,1,nobs) );
else
   error('Missing required field SolarZenithAngle')
end
%
if (isfield(geo,'SolarAzimuthAngle'))
   junk = geo.SolarAzimuthAngle;
   prof.solazi = single( reshape(junk,1,nobs) );
else
   error('Missing required field SolarAzimuthAngle')
end
%
%%%
% Unsure about "Height" (is it supposed to be zobs or salti?)
if (isfield(geo,'Height'))
   junk = geo.Height;
   prof.zobs = single( reshape(junk,1,nobs) );
else
   error('Missing required field Height')
end
%%%
prof.pobs = zeros(1,nobs,'single');
prof.upwell = ones(1,nobs,'int32');
iobs = 1:nobs;
prof.atrack = int32( 1 + floor((iobs-1)/270) );
prof.xtrack = int32( 1 + mod(floor((iobs-1)/9),30) );
%wrong prof.ifov = 1 + mod(iobs,9);
prof.ifov = int32( 1 + mod(iobs-1,9) );
%
if (isfield(pd,'ES_RealLW'))
   junk = pd.ES_RealLW;
   s = size(junk);
   if (s(1) ~= nchanLW)
      error('unexpected number of LW channels')
   end
   nobs_pd = round(prod(s(2:end))); % exact integer
   if (nobs_pd ~= nobs)
      error('Product_Data and Geolocation data have different nobs')
   end
   prof.robs1 = zeros(nchan,nobs,'single');
   ic = 1:nchanLW;
   prof.robs1(ic,:) = reshape(junk,nchanLW,nobs);
else
   error('Missing required field ES_RealLW')
end
%
if (isfield(pd,'ES_RealMW'))
   junk = pd.ES_RealMW;
   s = size(junk);
   if (s(1) ~= nchanMW)
      error('unexpected number of MW channels')
   end
   ic = nchanLW + (1:nchanMW);
   prof.robs1(ic,:) = reshape(junk,nchanMW,nobs);
else
   error('Missing required field ES_RealMW')
end
%
if (isfield(pd,'ES_RealSW'))
   junk = pd.ES_RealSW;
   s = size(junk);
   if (s(1) ~= nchanSW)
      error('unexpected number of SW channels')
   end
   ic = nchanLW + nchanMW + (1:nchanSW);
   prof.robs1(ic,:) = reshape(junk,nchanSW,nobs);
else
   error('Missing required field ES_RealSW')
end
%
% Overall quality flag
prof.robsqual = qual;


% Assign non-standard fields
prof.udef = zeros(20,nobs,'single');
prof.iudef = zeros(10,nobs,'int32');

prof.iudef(3,:) = ones(size(prof.rtime)) * str2num(pd_gran0_a.N_Granule_ID{1}(4:end));
prof.iudef(4,:) = ones(size(prof.rtime)) * double(pd_gran0_a.Descending_Indicator);
prof.iudef(5,:) = ones(size(prof.rtime)) * double(pd_gran0_a.N_Beginning_Orbit_Number);

%
% Interpolate X,Y,Z at MidTime to rtime
if (isfield(geo,'SCPosition') & isfield(geo,'MidTime'))
  try
   xyz = geo.SCPosition; % [3 x 4*n]
   mtime = double(geo.MidTime)*1E-6 - seconds1958to2000; % [1 x 4*n]
   isub = prof.rtime > 0;
   msel = [logical(1); diff(mtime) > 0];
   prof.udef(10,isub) = interp1(mtime(msel),xyz(1,msel),prof.rtime(isub),'linear','extrap');
   prof.udef(11,isub) = interp1(mtime(msel),xyz(2,msel),prof.rtime(isub),'linear','extrap');
   prof.udef(12,isub) = interp1(mtime(msel),xyz(3,msel),prof.rtime(isub),'linear','extrap');
  catch e;
   e
   keyboard
  end
end
%
prof.iudef( 8,:) = QAbitsLW;
prof.iudef( 9,:) = QAbitsMW;
prof.iudef(10,:) = QAbitsSW;


pattr = {{'profiles' 'rtime' 'seconds since 0z 1 Jan 2000'}, ...
         {'profiles' 'iudef(3,:)' 'Granule ID {granid}'}, ...
         {'profiles' 'iudef(4,:)' 'Descending Indicator {descending_ind}'}, ...
         {'profiles' 'iudef(5,:)' 'Beginning Orbit Number {orbit_num}'}, ...
         {'profiles' 'iudef(8,:)' 'longwave QA bits {QAbitsLW}'}, ...
         {'profiles' 'iudef(9,:)' 'mediumwave QA bits {QAbitsMW}'}, ...
         {'profiles' 'iudef(10,:)' 'shortwave QA bits {QAbitsSW}'}, ...
         {'profiles' 'udef(10,:)' 'spacecraft X coordinate {X}'}, ...
         {'profiles' 'udef(11,:)' 'spacecraft Y coordinate {Y}'}, ...
         {'profiles' 'udef(12,:)' 'spacecraft Z coordinate {Z}'}, ...
        };

	% Set findex to be the Granule number
% The Goal of findex is to uniquely identify a FoV:
% [ifov, xtrack, atrack, findex] - hence the "granule 

prof.findex = prof.iudef(3,:);

%
%%% end of function %%%
