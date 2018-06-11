function [head, hattr, prof0, pattr] = test_driver_sarta_cloud(rtpfile)
rtp_addpaths  % rtpread/write
addpath ~/git/matlib/clouds/sarta  % driver_sarta_cloud_rtp

run_sarta.cloud = 1;
run_sarta.clear = -1;  % skip running clear sarta. use existing

% ************************************************
% EDIT FOR TEST
run_sarta.cumsum = -1;
%************************************************

% read rtp file
[head, hattr, prof, pattr] = rtpread(rtpfile);

% run cloudy sarta (& klayers, if necessary)
[prof0, oslabs] = driver_sarta_cloud_rtp(head, hattr, prof, pattr, ...
                                         run_sarta);


