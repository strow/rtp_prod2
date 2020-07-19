function p = p60_ecmwf(psfc, lhalf);

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
% Note:  ecmwf_a/b assume using Pascal's, so you will see
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
ecmwf_a= [
    0.000000,    20.000000,    38.425343,    63.647804,    95.636963, ...
  134.483307,   180.584351,   234.779053,   298.495789,   373.971924, ...
  464.618134,   575.651001,   713.218079,   883.660522,  1094.834717, ...
 1356.474609,  1680.640259,  2082.273926,  2579.888672,  3196.421631, ...
 3960.291504,  4906.708496,  6018.019531,  7306.631348,  8765.053711, ...
10376.126953, 12077.446289, 13775.325195, 15379.805664, 16819.474609, ...
18045.183594, 19027.695313, 19755.109375, 20222.205078, 20429.863281, ...
20384.480469, 20097.402344, 19584.330078, 18864.750000, 17961.357422, ...
16899.468750, 15706.447266, 14411.124023, 13043.218750, 11632.758789, ...
10209.500977,  8802.356445,  7438.803223,  6144.314941,  4941.778320, ...
 3850.913330,  2887.696533,  2063.779785,  1385.912598,   855.361755, ...
  467.333588,   210.393890,    65.889244,     7.367743,     0.000000, ...
    0.000000 ]';
%
ecmwf_b = [
   0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, ...
   0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, ...
   0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, ...
   0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, ...
   0.00007582, 0.00046139, 0.00181516, 0.00508112, 0.01114291, 0.02067788, ...
   0.03412116, 0.05169041, 0.07353383, 0.09967469, 0.13002251, 0.16438432, ...
   0.20247594, 0.24393314, 0.28832296, 0.33515489, 0.38389215, 0.43396294, ...
   0.48477158, 0.53570992, 0.58616841, 0.63554746, 0.68326861, 0.72878581, ...
   0.77159661, 0.81125343, 0.84737492, 0.87965691, 0.90788388, 0.93194032, ...
   0.95182151, 0.96764523, 0.97966272, 0.98827010, 0.99401945, 0.99763012, ...
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
phalf = ( ecmwf_a*ones(1,nprof) + ...
   ( ecmwf_b*ones(1,nprof) ) .* (ones(61,1)*psfc)*100 )/100;

if (lhalf == 1)
   p = phalf(2:61,:);
else
   % Average half-levels to get full-level pressures
   p = ( phalf(1:60,:) + phalf(2:61,:) )/2;
end

%%% end of function %%%
