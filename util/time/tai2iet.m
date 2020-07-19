%
% NAME
%   tai2iet - take TAI 58 to IET
%
% SYNOPSIS
%   iet = tai2iet(tai)
%
% INPUT
%   tai  - TAI time, seconds from 1 Jan 1958
%
% OUTPUT
%   iet  - IET time, microseconds from 1 Jan 1958
%

function iet = tai2iet(tai)

iet = tai * 1e6;

