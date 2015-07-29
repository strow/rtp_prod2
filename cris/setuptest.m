crisdir='/asl/data/cris/ccast/sdr60_hr/2015/049';
crisfiles = dir(fullfile(crisdir, '*.mat'));
olddir=cd('/asl/s1/sbuczko1/testoutput');
findex=30;

disp('>>> Prior to addpath');
which ccast2rtp
which rtpwrite

addpath(genpath('~/git/rtp_prod2'))

disp('>>> After addpath');
which ccast2rtp
which rtpwrite

fnCrisInput = fullfile(crisdir, crisfiles(findex).name);
% $$$ fnCrisOutput = '/dev/null';
fnCrisOutput = '/asl/s1/sbuczko1/testoutput/test.rtp';

create_cris_ccast_hires_rtp(fnCrisInput, fnCrisOutput);

disp('>>> After create_cris...')
which ccast2rtp
which rtpwrite
