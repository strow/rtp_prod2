%
% NAME
%   tai2airs - take RTP TAI 58 to AIRS TAI 93
%
% SYNOPSIS
%   airs = tai2airs(tai)
%
% INPUT
%   tai  - RTP TAI 58, seconds from 1 Jan 1958
%
% OUTPUT
%   airs - AIRS TAI 93, seconds from 1 Jan 1993
%

function airs = tai2airs(tai)

airs = tai - (12784 * 86400 + 27);

