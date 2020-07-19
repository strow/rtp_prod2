function [indtest, deltas] = matchWN2Ind(ftest, vchan)
% MATCHWN2IND compare wavenumbers provided in array ftest against those stored
% in head.vchan to find nearest head.[iv]chan elements
% corresponding to ftest

%/////////////////////////////////////////////////
%
% INPUT:
%   ftest   : array of wavenumbers to test against vchan array
%   vchan   : head.vchan type array of spectral channel wavenumbers
%
% OUTPUT:
%   indtest  : array of size(ftest) containing array indices into
%             vchan corresponding to values nearest ftest entries
%   deltas  : delta between ftest and vchan entries (for
%             diagnotics)
%
%/////////////////////////////////////////////////

indtest = zeros(size(ftest));
deltas = NaN(size(ftest));

for i=1:length(ftest)
    testvals = ones(size(vchan))*ftest(i);
    [deltas(i), indtest(i)] = min(abs(vchan - testvals));
end
