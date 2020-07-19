%
% NAME
%   cris_vchan - full CrIS grid with guard channels
%
% SYNOPSIS
%   vchan = cris_vchan(ng, userLW, userMW, userSW)
%
% INPUTS
%   ng      - number of guard channels
%   userLW  - LW user grid struct
%   userMW  - MW user grid struct
%   userSW  - SW user grid struct
%
% OUTPUTS
%   vchan   - combined frequency grid
%
% DISCUSSION
%   The grid setup vbase + (0 : n-1) * dv is for numeric stability.
%   The matlab fucion linspace is probably just as good but will not
%   be better than the above.
%
% AUTHOR
%  H. Motteler, 18 Sep 2014
%

function vchan = cris_vchan(ng, userLW, userMW, userSW)

n1 = round((userLW.v2 - userLW.v1) / userLW.dv) + 1;
v1 = userLW.v1 - ng * userLW.dv + (0 : n1 + 2*ng -1) * userLW.dv;

n2 = round((userMW.v2 - userMW.v1) / userMW.dv) + 1;
v2 = userMW.v1 - ng * userMW.dv + (0 : n2 + 2*ng -1) * userMW.dv;

n3 = round((userSW.v2 - userSW.v1) / userSW.dv) + 1;
v3 = userSW.v1 - ng * userSW.dv + (0 : n3 + 2*ng -1) * userSW.dv;

vchan = [v1, v2, v3];

