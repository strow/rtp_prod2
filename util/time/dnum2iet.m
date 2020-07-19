%
% NAME
%   dnum2iet - take Matlab date numbers to IET
%
% SYNOPSIS
%   iet = dnum2iet(dnum)
%
% INPUT
%   dnum  - Matlab serial date numbers
%
% OUTPUT
%   iet   - IET time, microseconds from 1 Jan 1958
%

function iet = dnum2iet(dnum)

iet = dnum2tai(dnum) * 1e6;

