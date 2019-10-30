%
% NAME
%   dnum2tai - take Matlab date numbers to TAI 58
%
% SYNOPSIS
%   tai = dnum2tai(dnum)
%
% INPUT
%   dnum  - Matlab serial date numbers
%
% OUTPUT
%   tai   - TAI time, seconds from 1 Jan 1958
%
% NOTE
%   takes leap seconds into account via utc2tai
%

function tai = dnum2tai(dnum)

tai = utc2tai(86400 * (dnum - datenum('1 Jan 1958')));

