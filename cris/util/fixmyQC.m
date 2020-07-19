%
% NAME
%   fixmyQC - demo of the ccast L1b_stat flags
%
% SYNOPSIS
%   [eLW, eMW, eSW] = fixmyQC(L1a_err, L1b_stat)
%
% INPUTS
%   L1a_err   - 30 x nscan L1a error flags
%   L1b_stat  - checkSDR status struct
%
% OUTPUTS
%   eLW  - 9 x 30 x nscan LW error flags
%   eMW  - 9 x 30 x nscan MW error flags
%   eSW  - 9 x 30 x nscan SW error flags
%
% DISCUSSION
%   demo using the ccast L1b_stat flags.  Output arrays are the 
%   same shape as L1b_err.  Output is the logical OR of L1A error,
%   negative radiance, and calibration NaN flags.  For a single
%   3-band flag set e3 = eLW | eMW | eSW after the call.
%
%   for more refined QC adjustments use checkSDR; but note this
%   requires most of the data from a ccast SDR granule.
%
% AUTHOR
%  H. Motteler, 16 Sep 2017
%

function [eLW, eMW, eSW] = fixmyQC(L1a_err, L1b_stat)

% extend L1a_err to a 9 x 30 x nscan array
L1a_tmp = L1a_err;
[m, n] = size(L1a_tmp);
L1a_tmp = ones(9,1) * L1a_tmp(:)';
L1a_tmp = reshape(L1a_tmp, 9, m, n);

% per-band OR of L1A error and L1b status flags
eLW = L1a_tmp | L1b_stat.negLW | L1b_stat.nanLW;
eMW = L1a_tmp | L1b_stat.negMW | L1b_stat.nanMW;
eSW = L1a_tmp | L1b_stat.negSW | L1b_stat.nanSW;

