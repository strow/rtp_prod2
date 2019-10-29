%
% NAME
%   finterp - two-transform Fourier interpolation
%
% SYNOPSIS
%   [rad2, frq2] = finterp(rad1, frq1, dv2, opt)
%
% INPUTS
%   rad1   - radiances, m x n array
%   frq1   - frequencies, m-vector
%   dv2    - desired rad2 frequency spacing
%   opt    - optional parameters
%
% opt fields
%   info   - print some basic transform stats
%   tol    - tolerance for the rational approximation of dv1/dv2.  
%
% OUTPUTS
%   rad2   - interpolated radiances, k x n array
%   frq2   - interpolated frequencies, k-vector
%
% DISCUSSION
%   see doc/finterp.pdf for the derivations used here.
%
% HM, 20 Sep 2014
%

function [rad2, frq2] = finterp(rad1, frq1, dv2, opt)

% defaults
tol = 1e-6;
info = 0;

% options
if nargin == 4
  if isfield(opt, 'tol'), tol = opt.tol; end
  if isfield(opt, 'info'), info = opt.info; end
end

% check that array sizes match
frq1 = frq1(:);
[m, nobs] = size(rad1);
if m ~= length(frq1)
  error('rad1 and frq1 sizes do not match')
end

%-----------------------------------
% set up interferometric parameters
%-----------------------------------

v1 = min(frq1);
v2 = max(frq1);
dv1 = frq1(2) - frq1(1);

% get rational approx to dv1/dv2
[m1, m2] = rat(dv1/dv2, tol);

% get the tranform sizes
for k = 0 : 24
  if m2 * 2^k * dv1 >= v2, break, end
end
N1 = m2 * 2^k;
N2 = m1 * 2^k;

% get (and check) dx
dx1 = 1 / (2*dv1*N1);
dx2 = 1 / (2*dv2*N2);
% if ~isclose(dx1, dx2, 4)
%   error('dx1 and dx2 are different')
% end
dx = dx1;

if info
  fprintf(1, 'finterp: N1 = %7d, N2 = %5d, dx = %6.3e\n', N1, N2, dx);
end

%----------------------
% do the interpolation 
%----------------------

% embed rad1 in a 0 to Vmax grid
ftmp = (0:N1)' * dv1;
rtmp = zeros(N1+1, nobs);
ix = interp1(ftmp, (1:N1+1)', frq1, 'nearest');
rtmp(ix, :) = rad1;

% take radiance to interferograms
igm1 = ifft([rtmp; flipud(rtmp(2:N1, :))]);
igm1 = igm1(1:N1+1, :);
clear rtmp

% extend or truncate igm1 to igm2
igm2 = zeros(N2+1, nobs);
k = min(N1+1, N2+1);
igm2(1:k, :) = igm1(1:k, :);
clear igm1

% take interferograms to radiance
rad2 = fft([igm2(1:N2+1,:); flipud(igm2(2:N2,:))]);
frq2 = (0:N2)' * dv2;
clear igm2

% return just the input band
ix = find(v1 <= frq2 & frq2 <= v2);
rad2 = rad2(ix, :);
frq2 = frq2(ix);

