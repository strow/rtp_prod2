%
% NAME
%  seq_match -- find the matching subsequence of two sequences
%
% SYNOPSIS
%  function [i, j] = seq_match(a, b, d) 
%
% INPUTS
%   a, b  - sorted input sequences
%   d     - optional max difference for matches
%
% OUTPUTS
%   i, j  - indices of matches in a and b
%
% DISCUSSION
%   For sorted sequences A and B, seq_match returns a list of 
%   all pairs u, v such that v is the closest element in B to u,
%   and u is the closest element in A to v.  This something like
%   intersection for matches that are close but not identical.
%
%   More specifically, if [i, j] = seq_match(a, b), then a(i) is
%   the list of matches in a, and b(j) the list of matches in b.
%   The index lists i and j have the same length.  If d is given,
%   only matches where the distance between pairs is less than or
%   equal to d are kept.
%
%   seq_match works by finding all fixed-points of the nearest-
%   neighbor relation starting from every point in A, and as a
%   check from every point in B.  It converges quickly for most
%   sequences.  If d is not specified, seq_match always returns 
%   at least one matching pair, even for disjoint sequences.
%
% AUTHOR
%  H. Motteler, 2 June 2013
%

function [i, j] = seq_match(a, b, d)

% move input to column vectors
a = a(:);  b = b(:);

% check that input is sorted
if ~issorted(a) || ~issorted(b)
  error('input must be in sorted order')
end

% check for min sequence length
if length(a) < 2 || length(b) < 2
  error('sequences must have length at least 2')
end

% for each element of b, get index in a of the closest element of a
ia = interp1(a, (1:length(a))', b, 'nearest', 'extrap');

% for each element of a, get index in b of the closest element of b
ib = interp1(b, (1:length(b))', a, 'nearest', 'extrap');

% set up loops
i = unique(ia(ib));
j = unique(ib(ia));
ix = []; jx = [];
ic = 0; jc = 0;

% nearest-neighbor loop from a
while ~isequal(i, ix)
  ix = i;
  i = unique(ia(ib(i)));
  ic = ic + 1;
end

% nearest-neighbor loop from b
while ~isequal(j, jx)
  jx = j;
  j = unique(ib(ia(j)));
  jc = jc + 1;
end

% check the match
jx = ib(i); 
ix = ia(j);
if ~isequal(jx, j) || ~isequal(ix, i)
  fprintf(1, 'seq_match WARNING: mismatch after convergence\n')
end

% drop matches greater than d
if nargin == 3
  iok = find(abs(a(i) - b(j)) <= d);
  i = i(iok);
  j = j(iok);
end

% check loop counts
% fprintf(1, 'seq_match loops: ic = %d, jc = %d\n', ic, jc);

