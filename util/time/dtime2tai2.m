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
% DISCUSSION
%   dependds on undocumented features of datetime
%
% AUTHOR
%   H. Motteler, 15 Mar 2015
%

function tai = dtime2tai(dtime);

% TAI epoch base with Matlab UTC leap seconds
d58 = datetime('1958-01-01T00:00:00.000Z','timezone','UTCLeapSeconds');

% convert regular datetime to UTC leap seconds
tmp = dtime;
tmp.TimeZone = 'UTCLeapSeconds';
tmp.Year   = dtime.Year;
tmp.Month  = dtime.Month;
tmp.Day    = dtime.Day;
tmp.Hour   = dtime.Hour;
tmp.Minute = dtime.Minute;
tmp.Second = dtime.Second;

% Matlab UTC leap seconds are 10 seconds behind
tai = seconds(tmp - d58) + 10;

