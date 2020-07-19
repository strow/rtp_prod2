%
% NAME
%   airs2dnum - take AIRS TAI 93 to Matlab date numbers
%
% SYNOPSIS
%   dnum = airs2dnum(airs)
%
% INPUT
%   airs - AIRS TAI 93, seconds from 1 Jan 1993
%
% OUTPUT
%   dnum  - Matlab serial date numbers
%

function dnum = airs2dnum(airs)

dnum = tai2dnum(airs + 12784 * 86400 + 27);

