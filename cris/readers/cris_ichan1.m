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

% ichan order
b0 = 0;
b1 = b0 + n1;  B1 = b0+1 : b1;
b2 = b1 + n2;  B2 = b1+1 : b2;
b3 = b2 + n3;  B3 = b2+1 : b3;
g1 = b3 + ng;  G1 = b3+1 : g1;
g2 = g1 + ng;  G2 = g1+1 : g2;
g3 = g2 + ng;  G3 = g2+1 : g3;
g4 = g3 + ng;  G4 = g3+1 : g4;
g5 = g4 + ng;  G5 = g4+1 : g5;
g6 = g5 + ng;  G6 = g5+1 : g6;

% vchan order
ichan = [G1, B1, G2, G3, B2, G4, G5, B3, G6]';
