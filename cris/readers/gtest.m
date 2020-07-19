
% guard band demo

sg = 2;      % number of src guard chans
dg = 4;      % number of dst guard chans
nchan = 6;   % number regular channels

ng = min(sg, dg);            % guard chans to copy
nsrc = nchan + 2*sg;         % total src channels 
ndst = nchan + 2*dg;         % total dst channels
ncopy = nchan + 2*ng;        % total channels to copy

% src = 1 : nsrc;            % fake src data
src = [sg:-1:1, 1:nchan, 1:sg];
% src = [1:sg, 1:nchan, sg:-1:1];    

dst = ones(1, ndst) * NaN;   % initialize dst

si = sg - ng + (1 : ncopy);  % sr index
di = dg - ng + (1 : ncopy);  % dst index

dst(di) = src(si);           % copy the data

src
dst

