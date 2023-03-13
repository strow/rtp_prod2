function [A,V] = surfacearea_sphericalzones(lat)

%% see http://mathworld.wolfram.com/SphericalSegment.html
%% see http://mathworld.wolfram.com/Zone.html
%% see SphericalSegment.pdf
%%
%% lat is an array of latitudes in DEGREES
%%
%% A = 2 * pi * R * H
%% V  = 1/6*pi*H*(3*R1*R1 + 3*R2*R2 + H*H);
%% where R = radius
%%       R1 = R cos(lat1)
%%       R2 = R cos(lat2)
%%       H = heightdiff = R sin(lat2) - R sin (lat1) = R (sin(lat2)-sin(lat1))
%% answers are normalized to A/Awhole, V/Vwhole
%%
%% so for example if lat1,lat2 = [-90,+90]   
%%                 A = 2 * pi *R^2 * (sin(+90) - sin(-90)) = 4 pi R^2 = surface area of sphere
%% so for example if lat1,lat2 = [0,+90]   
%%                 A = 2 * pi *R^2 * (sin(+90) - sin(0)) = 2 pi R^2 = surface area of hemisphere
%% so for example if lat1,lat2 = [0,+60]   
%%                 A = 2 * pi *R^2 * (sin(+60) - sin(0)) = 2*0.866 pi R^2 
%% so for example if lat1,lat2 = [-30,+30]   
%%                 A = 2 * pi *R^2 * (sin(+30) - sin(-30)) = 2 pi R^2 = surface area of hemisphere = 1/2 area of sphere
%% so for example if lat1,lat2 = [+00,+30]   
%%                 A = 2 * pi *R^2 * (sin(+30) - sin(+00)) =   pi R^2 = 1/4 area of sphere = 1/2 area of hemisphere
%% so for example if lat1,lat2 = [+30,+90]   
%%                 A = 2 * pi *R^2 * (sin(+90) - sin(+30)) =   pi R^2 = 1/4 area of sphere = 1/2 area of hemisphere

if length(lat) < 2
  error('lat needs to be 2 points')
end

R   = 1;
lat = sort(lat);
H   = R*sin(pi/180*lat);

A = 2 * pi * R * H;   %plot(lat,A/(4*pi),'o-')
%%% diff(A) = 2 pi R diff(H) = 2 pi R^2 diff(sin x) = 2 pi R^2 (sin x(i) - sin x(j))
%%%    suppose x(i) = x(j) + dx ==> sin x(i) - sin x(j) = sin (x(j)+dx) - sin x(j)
%%%                                                     = sin x(j) cos dx + cos x(j) sin dx - sin x(j)
%%%                                                     ~ cos(x(j)) dx    if dx --> 0
%%%         = 2 pi R^2 cos xav(i) dx
%%% IN OTHER WORDS we ALREADY have the cos x dx factored in here!!!!!!!!!
A = diff(A);

Rx = R*cos(pi/180*lat);
R1 = Rx(1:end-1);
R2 = Rx(2:end);
H  = diff(H);
V  = 1/6*pi*H.*(3*R1.*R1 + 3*R2.*R2 + H.*H);

A_whole = 4*pi*R^2;
V_whole = 4/3*pi*R^3;

A = A/A_whole;   %% assuming lat spans [-90,+90] deg, sum(A) = 1 as we already have cos(x) dx factored in here
V = V/V_whole;
