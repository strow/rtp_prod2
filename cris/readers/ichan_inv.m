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
%

function ichan = cris_ichan(ng, n1, n2, n3)

k0 = 0;
k1 = k0 + n1 + 2 * ng;
k2 = k1 + n2 + 2 * ng;

G1 = k0 + (1:ng); B1 = k0 + ng + (1:n1); G2 = k0 + ng + n1 + (1:ng);
G3 = k1 + (1:ng); B2 = k1 + ng + (1:n2); G4 = k1 + ng + n2 + (1:ng);
G5 = k2 + (1:ng); B3 = k2 + ng + (1:n3); G6 = k2 + ng + n3 + (1:ng);

ichan = [B1, B2, B3, G1, G2, G3, G4, G5, G6];

