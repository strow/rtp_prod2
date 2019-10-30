%
% NAME
%   utc2dnum - take UTC 58 to Matlab date numbers
%
% SYNOPSIS
%   dnum = utc2dnum(utc)
%
% INPUT
%   utc   - UTC seconds since 1 Jan 1958
%
% OUTPUT
%   dnum  - Matlab serial date numbers
%

function dnum = utc2dnum(utc)

dnum = datenum('1 Jan 1958') + utc / 86400;

