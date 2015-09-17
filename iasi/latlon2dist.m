function [dist] = latlon2dist(lat1, lon1, lat2, lon2);

% function [dist] = latlon2dist(lat1, lon1, lat2, lon2);
%
% Calculate the approximate distance (in meters) between pairs of
% latitude and longitude points (in degrees).
%
% Input:
%    lat1 : (1 x nobs) ) first latitude (degrees, -90 to 90)
%    lon1 : (1 x nobs) first longitude (degrees, -180 to 360)
%    lat2 : (1 x nobs) second latitude (degrees, -90 to 90)
%    lon2 : (1 x nobs) second longitude (degrees, -180 to 360)
%
% Output:
%    dist : (1 x nobs) distance (meters) between lat,lon pairs
%

% Created: Scott Hannon, 13 April 2007 - total rewrite of old code of same name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following info (slightly written) from:
% Weisstein, Eric W. "Great Circle." From MathWorld--A Wolfram Web Resource.
% http://mathworld.wolfram.com/GreatCircle.html 
%
% The shortest path between two points on a sphere is a segment of a
% great circle. To find the great circle (geodesic) distance between
% two points located at latitude D and longitude L of (D1,L1)  and
% (D2,L2) on a sphere of radius R, convert spherical coordinates to
% Cartesian coordinates.
%
%    x = R sin(phi) cos(theta)
%    y = R sin(phi) sin(theta)
%    z = R cos(phi)
%
% Note that longitude L is equivalent to theta, while the latitude D
% is related to the phi of spherical coordinates by D = 90 degrees - phi,
% so the conversion to Cartesian coordinates replaces sin(phi) and
% cos(phi) by cos(D) and sin(D), respectively.
% 
%    r_i = R[cos(Li)cos(Di); sin(Li)cos(Di); sin(Di)]
%
% Now find the angle alpha between r_1 and r_2 using the dot product
%
%   cos(alpha) = r_1 dot r_2
%      = cos(D1)cos(D2) {sin(L1)sin(L2) + cos(L1)cos(L2)} + sin(D1)sin(D2)
%      = cos(D1)cos(D2)cos(L1-L2) + sin(D1)sin(D2)
%
% The great circle distance is then
%   d = R arccos( cos(alpha) )
%
% For the Earth, the equatorial radius is a approx 6378 km (3963 miles).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

R_earth = 6.37E+06; % Approximate mean Earth radius in meters
conv=pi/180;        % Conversion factor for degrees to radians

% Convert from degrees to radians
rlat1 = conv*lat1;
rlon1 = conv*lon1;
rlat2 = conv*lat2;
rlon2 = conv*lon2;

cosalpha = cos(rlat1).*cos(rlat2).*cos(rlon1-rlon2) + sin(rlat1).*sin(rlat2);

dist = R_earth*acos( cosalpha );

%%% end of function %%%
