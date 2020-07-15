%
% NAME
%   cris_ichan - sarta ichan indices in frequency order
%
% SYNOPSIS
%   ichan = cris_ichan(ng, sg, n1, n2, n3)
%
% INPUTS
%   ng  - desired number of guard channels
%   sg  - number of sarta guard channels 
%   n1  - number of true channels in band 1
%   n2  - number of true channels in band 2
%   n3  - number of true channels in band 3
%
% OUTPUTS
%   ichan - ichan indices in frequency order
%
% DISCUSSION
%   sarta assigns indices and frequencies to channels in a table,
%   following a scheme where regular channels are listed first and
%   guard channels are at the end.  The associated RTP fields are
%   ichan and vchan.  sarta has channels sorted by channel index
%   (ichan order) while CrIS is sorted by frequency (vchan order).
%
%   cris_ichan takes CrIS true band sizes, the desired number of
%   guard channels, and the number of guard channels sarta expects
%   and returns an ichan index to match the CrIS freqency grid.
%
%   The function returns an ichan index with ng guard bands for a
%   sarta that expects sg guard bands, and works for 0 <= ng <= sg,
%   0 <= n1, n2 <= 0, and 0 <= n3.
%
% AUTHOR
%  H. Motteler, 20 Mar 2015
%

function ichan = cris_ichan(ng, sg, n1, n2, n3)

if ng > sg
  error('you asked for too many guard chans')
end

% guard chan diff
k = sg - ng;

% ichan order
b0 = 0;
b1 = b0 + n1;  B1 = b0+1   : b1;     % band 1 true
b2 = b1 + n2;  B2 = b1+1   : b2;     % band 2 true
b3 = b2 + n3;  B3 = b2+1   : b3;     % band 3 true
g1 = b3 + sg;  G1 = b3+1+k : g1;     % band 1 lower guard
g2 = g1 + sg;  G2 = g1+1   : g2-k;   % band 1 upper guard
g3 = g2 + sg;  G3 = g2+1+k : g3;     % band 2 lower guard
g4 = g3 + sg;  G4 = g3+1   : g4-k;   % band 2 upper guard
g5 = g4 + sg;  G5 = g4+1+k : g5;     % band 3 lower guard 
g6 = g5 + sg;  G6 = g5+1   : g6-k;   % band 3 upper guard

% vchan order
ichan = [G1, B1, G2, G3, B2, G4, G5, B3, G6];

