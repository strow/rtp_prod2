%
% NAME
%   iet2dnum - take IET to Matlab date numbers
%
% SYNOPSIS
%   dnum = iet2dnum(iet)
%
% INPUT
%   iet   - IET time, microseconds from 1 Jan 1958
%
% OUTPUT
%   dnum  - Matlab serial date numbers
%

function dnum = iet2dnum(iet)

dnum = tai2dnum(iet * 1e-6);

