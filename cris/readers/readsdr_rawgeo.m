function [geo] = readsdr_rawgeo(hfile);

% function [geo] = readsdr_rawgeo(hfile);
%
% Read a CrIS HDF5 SDR "Geolocation" file and return the entire
% contents in a structure
% Note: see "readsdr_pd.m" for CrIS HDF5 SDR "Product_Data" file.
%
% Input:
%    hfile : [string] name of CrIS HDF5 SDR "Geolocation" file
%
% Output:
%    geo   : [structure] CrIS SDR Geolocation with 16 fields
%

% Created: 20 January 2011, Scott Hannon - based on readsrd_rawpd.m (no
%    code changes other than name & comments)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

d = dir(hfile);
if (length(d) ~= 1)
   hfile
   error('bad filename')
end

% Get info about file contents
info = hdf5info(hfile);
nfields = length(info.GroupHierarchy.Groups(1).Groups(1).Datasets);

% Read all fields
geo =[];
for ii=1:nfields
   [~, fname, ext] = fileparts(info.GroupHierarchy.Groups(1).Groups(1).Datasets(ii).Name);
   eval(['geo.' fname '=hdf5read(info.GroupHierarchy.Groups(1).Groups(1).' ...
      'Datasets(ii));'])
end

%%% end of function %%%
