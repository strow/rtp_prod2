%
% NAME
%   cris_ichan - CrIS sarta ichan indices
%
% SYNOPSIS
%   ichan = cris_ichan(ng, n1, n2, n3)
%
% INPUTS
%   ng  - number of guard channels
%   n1  - number of real channels in band 1
%   n2  - number of real channels in band 2
%   n3  - number of real channels in band 3
%
% OUTPUTS
%   ichan - ichan indices (with guard bands at the end)
%
% DISCUSSION
%   sarta ichan indices for vchan in frequency order
%
% AUTHOR
%  H. Motteler, 18 Sep 2014
%  L. Strow, 18, Mar 2015: changed to reflect guard channels are
%     defined to line up in order after the real channels.

function ichan = cris_ichan(ng, n1, n2, n3)

% Total number of real channesl
n = n1 + n2 + n3;

% Guard channel ID's start after real channels
G1 = n + (1:ng);       B1 = (1:n1);           G2 = G1(end) + (1:ng);
G3 = G2(end) + (1:ng); B2 = B1(end) + (1:n2); G4 = G3(end) + (1:ng);
G5 = G4(end) + (1:ng); B3 = B2(end) + (1:n3); G6 = G5(end) + (1:ng);

ichan = [G1, B1, G2, G3, B2, G4, G5, B3, G6]';

