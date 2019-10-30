%
% NAME
%   dnum2airs - take Matlab date numbers to AIRS TAI 93
%
% SYNOPSIS
%   airs = dnum2airs(dnum)
%
% INPUT
%   airs - AIRS TAI 93, seconds from 1 Jan 1993
%
% OUTPUT
%   dnum  - Matlab serial date numbers
%

function airs = dnum2airs(dnum)

airs = dnum2tai(dnum) - (12784 * 86400 + 27);

