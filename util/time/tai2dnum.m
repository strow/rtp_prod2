%
% NAME
%   tai2dnum - take TAI 58 to Matlab date numbers
%
% SYNOPSIS
%   dnum = tai2dnum(tai)
%
% INPUT
%   tai   - TAI time, seconds from 1 Jan 1958
%
% OUTPUT
%   dnum  - Matlab serial date numbers
%

function dnum = tai2dnum(tai)

dnum =  datenum('1 Jan 1958') + tai2utc(tai) / (24 * 60 * 60);

