%
% NAME
%   guard_ind - indices for copying data with guard bands
%
% SYNOPSIS
%   [si, di] = guard_ind(sg, dg, nc)
%
% INPUTS
%   sg   - number of src guard chans
%   dg   - number of dst guard chans
%   nc   - number of regular channels
%
% OUTPUTS
%   si   - index into source data
%   di   - index into destination data
%
% AUTHOR
%  H. Motteler, 18 Sep 2014
%

function [si, di] = guard_ind(sg, dg, nc)

ng = min(sg, dg);   % guard chans to copy
nsrc = nc + 2*sg;   % total src channels 
ndst = nc + 2*dg;   % total dst channels
ncopy = nc + 2*ng;  % total channels to copy

si = sg - ng + (1 : ncopy);  % sr index
di = dg - ng + (1 : ncopy);  % dst index

