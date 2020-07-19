%
% test guard_ind
%

sg = 2;   % number of src guard chans
dg = 4;   % number of dst guard chans
nc = 6;   % number regular channels

nsrc = nc + 2*sg;   % total src channels 
ndst = nc + 2*dg;   % total dst channels

src = [sg:-1:1, 1:nc, 1:sg];  % fake src data

dst = ones(1, ndst) * NaN;    % initialize dst

[si, di] = guard_ind(sg, dg, nc);

dst(di) = src(si);           % copy the data

src
dst

