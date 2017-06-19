function indl = get_equal_area_sub_indices(lat,limit);

% Select latitude indices to ensure equal area weighting
%
% Input: latitude (degrees)
%        limit (reduces size of subset) (NOT required)
%
% Output: indl (logical array with subset selection)
%
% Note:  to subset array with output do indl = find(indl);

if nargin == 1
    limit = 0.011;   % Present 0.7% of data limit
end

ix = rand(size(lat)) < abs(cos(deg2rad(lat)));
iy = rand(size(lat)) < limit;

indl = ix & iy;