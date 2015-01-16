% airxbcal_read_test.m

% Temporary location of read_airxbcal.m
addpath /home/strow/cress/Work/Rtp_dev/Airs

% Need to move this to proper location
%  and, should we use this?
addpath ~/Matlab/FileExchange/Enhanced_dir/

% Location of AIRXBCAL year directories
dn = '/asl/data/airs/AIRXBCAL';

% rdir syntax let's you use '**' for any dir name
fnlist = rdir(fullfile(dn,'2013','**','*.hdf'))

% Pick a file to read
n = length(fnlist);
i = round(n/2);

% Read the AIRXBCAL file
tic;[p, pa, aux] = read_airxbcal(fnlist(i).name);toc

