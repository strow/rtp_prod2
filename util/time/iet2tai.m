%
% NAME
%   iet2tai - take IET to TAI 58
%
% SYNOPSIS
%   tai = iet2tai(iet)
%
% INPUT
%   iet - IET time, microseconds from 1 Jan 1958
%
% OUTPUT
%   tai - TAI time, seconds from 1 Jan 1958
%

function tai = iet2tai(iet)

tai = iet * 1e-6;

