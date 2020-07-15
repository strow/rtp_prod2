function p = p60_era5(psfc, lhalf);

% function [p] = p60_ecmwf( psfc, lhalf );
%
% Calculate the 60 ECMWF "full-level" pressures based upon the
% surface pressure.  If optional argument "lhalf" equals 1 then
% it returns "half-level" pressures instead.
%
% Input:
%    psfc  : (1 x nprof) surface pressure (mb)
%    lhalf : OPTIONAL (1 x 1) output half-levels? {1=true, 0=false=default}
%
% Output:
%    p     : (60 x nprof) ECMWF pressure levels (mb)
%

% Taken from Walter Wolf's grib package
%
% Note:  era5_a/b assume using Pascal's, so you will see
%        some *100 and /100's in the code to switch from
%        mbar to Pascals
%
% V1.0:  LLS, 8/17/01
% V1.1:  Scott Hannon, 28 August 2001 - changes so psfc can be a (1 x nprof)
% Update: 07 Apr 2009, S.Hannon - added code for optional half-levels output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin < 1 | nargin > 2)
   error('Unexpected number of input arguments')
end
if (nargin == 1)
   lhalf = 0;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sigma to half-level coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
era5_a= [
    0.000000,    18.608931,    42.897242,    69.520576,   107.415741, ...
  131.425507,   191.338562,   227.968948,   316.420746,   368.982361, ...
  492.616028,   564.413452,   729.744141,   926.344910,  1037.201172, ...
 1423.770142,  1729.448975,  2076.095947,  2677.348145,  3135.119385, ...
 3911.490479,  4799.149414,  6156.074219,  7311.869141,  8608.525391, ...
10584.631836, 12211.547852, 13881.331055, 15508.256836, 17008.789063, ...
17901.621094, 19031.289063, 19859.390625, 20219.664063, 20412.208594, ...
20361.816406, 20087.085938, 19608.572266, 18917.460938, 18006.925781, ...
16888.687500, 15596.695313, 14173.324219, 12668.257813, 11901.339844, ...
10370.175781,  8880.453125,  7470.343750,  6168.531250,  4993.796875, ...
 3955.960938,  3057.265625,  1961.500000,  1387.546875,   926.507813, ...
  424.414063,   202.484375,    62.781250,     3.757813,     0.000000, ...
    0.000000 ]';
%
era5_b = [
   0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, ...
   0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, ...
   0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, ...
   0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, ...
   0.000059,   0.000562,   0.001992,   0.005378,   0.011806,   0.022355,   ...
   0.032176,   0.051773,   0.077958,   0.099462,   0.124448,   0.168910,   ...
   0.203491,   0.242244,   0.285354,   0.332939,   0.384363,   0.438391,   ...
   0.493800,   0.549301,   0.576692,   0.630036,   0.680643,   0.727739,   ...
   0.770798,   0.809536,   0.843881,   0.873929,   0.911448,   0.931881,   ...
   0.949064,   0.969513,   0.980072,   0.988500,   0.995003,   0.997630,   ...
   1.00000000 ]';


%%%%%%%%%%%%
% Check psfc
%%%%%%%%%%%%
[nrow,ncol]=size(psfc);
if (nrow ~= 1)
   disp('Error: psfc must be a (1 x nprof) vector!')
   return
else
   nprof=ncol;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate pressure levels
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Half-level pressures
phalf = ( era5_a*ones(1,nprof) + ...
   ( era5_b*ones(1,nprof) ) .* (ones(61,1)*psfc)*100 )/100;

if (lhalf == 1)
   p = phalf(2:61,:);
else
   % Average half-levels to get full-level pressures
   p = ( phalf(1:60,:) + phalf(2:61,:) )/2;
end

%%% end of function %%%
