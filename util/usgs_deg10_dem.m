function [salti, landfrac] = usgs_deg10_dem(lat, lon, wgf);

% function [salti, landfrac] = usgs_deg10_dem(lat, lon, wgf);
%
% Return surface altitude and land fraction for the nearest
% point in the 10 points per degree lookup table.
% Note: resolution is roughly 11 km near the equator.
%
% Input:
%    lat : [1 x nobs ] latitude (degrees)
%    lon : [1 x nobs ] longitude (degrees)
%    wgf : matlab World grid file [optional]
% 
% Output:
%    salti    : [1 x nobs] surface altitude (meters)
%    landfrac : [1 x nobs] land fraction
%
% Sources: elevation is based on USGS GTOPO30 data. Land fraction
% is based on UMD (College Park) GLCF 1 km land cover classification
% data.  The original data has been spatially averaged (12x12 points)
% from 1/120 of a degree to 1/10 of a degree by Breno Imbiriba, UMBC.
%

% Created: 05 Jun 2007, Scott Hannon - based on ecmwf_dem.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Note: dem_file must contain fields landfrac and salti
% Note: DEM is structured
%    Loop lon = 0.05 : 0.10 : 359.95
%       Loop lat = 89.95 : -0.10 : -89.95


% Load ECMWF Digital Elevation Map file
if(exist('wgf','var'))
  load(wgf)
else
  load /asl/data/usgs/world_grid_deg10_v2.mat
end


% Check input
ibad = find( abs(lat) > 90.001);
if (length(ibad) ~= 0 )
   error('lat has values outside allowed -90:90 range')
end
ibad = find( lon < -180.001 | lon > 360.001);
if (length(ibad) ~= 0 )
   error('lon has values outside allowed -180:360 range')
end


% Find nearest lat point in dem
xlat = round(-(lat+0.05)*10) + 901; % 1 to 1800
ix = find(xlat < 1); % will happen if lat == 90
xlat(ix) = 1;
ix = find(xlat > 1800); % will happen if lat == -90
xlat(ix) = 1800;

% Find nearest lon point in dem
xlon = lon;
ix = find(lon < 0);
xlon(ix) = lon(ix) + 360;
xlon = round((xlon+0.05)*10);
%%%
%ix = find(xlon < 1); % impossible; already removed all negative lon
%xlon(ix) = 1;
%%%
ix = find(xlon > 3600); % will happen if lon >= 360
xlon(ix) = 1;

indx = xlat + 1800*(xlon - 1);

salti = salti(indx);
landfrac = landfrac(indx);

%%% end of function %%%
