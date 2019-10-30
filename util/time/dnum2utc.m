%
% NAME
%   dnum2utc - take Matlab date numbers to UTC 58
%
% SYNOPSIS
%   utc = dnum2utc(dnum)
%
% INPUT
%   dnum  - Matlab serial date numbers
%
% OUTPUT
%   utc   - UTC seconds since 1 Jan 1958
%

function utc = dnum2utc(dnum)

utc = (dnum - datenum('1 Jan 1958')) * 86400;

