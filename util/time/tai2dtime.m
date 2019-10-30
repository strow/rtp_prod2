%
% NAME
%   tai2dtime - take TAI 58 to Matlab datetime
%
% SYNOPSIS
%   dtime = tai2dtime(tai);
%
% INPUT
%   tai   - TAI time, seconds from 1 Jan 1958
%
% OUTPUT
%   dtime - a Matlab datetime object
%

function dtime = tai2dtime(tai);

dtime = datetime(utc2dnum(tai2utc(tai)), 'ConvertFrom', 'datenum');

