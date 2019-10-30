function [rham] = box_to_ham(rbox);

% function [rham] = box_to_ham(rbox);
%
% Convert boxcar/unapodized radiance to Hamming apodized radiance
% using the exact conversion equation:
%    rham(i) = 0.23*rbox(i-1) + 0.54*rbox(i) + 0.23*rbox(i+1)
% Any point where there is a discontinuity in rbox is invalid in
% rham (the first and last points which are ALWAYS invalid).
%
% Input:
%    rbox  -  [nchan x nobs] boxcar/unapodized radiance. The
%       radiance must be:
%       a) sorted by frequency (either ascending or descending)
%       b) point spacing 1/(2*L) where L is the maximum OPD
%       c) continuous (at least in part)
%
% Output:
%    rham  -  [nchan x nobs] Hamming apodized radiance
%

% Created: 12 July 2010, Scott Hannon
% Update: 12 Apr 2011, S.Hannon - bug fix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
d = size(rbox);
if (length(d)~= 2)
   error('Unexpected number of dimensions for rbox')
end
nchan = d(1);
nobs = d(2);
if (nchan < 3)
   error('Lead dimension of rbox must be at least 3')
end


% Convert rbox to rham
rham = rbox;
ii = 2:(nchan-1);
ilo = ii-1;
ihi = ii+1;
rham(ii,:) = 0.23*(rbox(ilo,:) + rbox(ihi,:)) + 0.54*rbox(ii,:);

%%% end of function %%%
