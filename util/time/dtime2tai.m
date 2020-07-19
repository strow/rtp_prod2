%
% NAME
%   dtime2tai - take Matlab datetime to TAI 58
%
% SYNOPSIS
%   tai = dtime2tai(dtime);
%
% INPUT
%   dtime - a Matlab datetime object
%
% OUTPUT
%   tai   - TAI time, seconds from 1 Jan 1958
%

function tai = dtime2tai(dtime);

tai = utc2tai(dnum2utc(datenum(dtime)));


