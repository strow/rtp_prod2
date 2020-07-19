%
% NAME
%   airs2tai - take AIRS TAI 93 to RTP TAI 58
%
% SYNOPSIS
%   tai = airs2tai(airs)
%
% INPUT
%   airs - AIRS TAI 93, seconds from 1 Jan 1993
%
% OUTPUT
%   tai  - RTP TAI 58, seconds from 1 Jan 1958
%

function tai = airs2tai(airs)

tai = airs + 12784 * 86400 + 27;

