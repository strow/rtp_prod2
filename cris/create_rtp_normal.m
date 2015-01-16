fdir = '/asl/data/cris/sdr60/2012/136/';
a = dir('/asl/data/cris/sdr60/2012/136/SCRIS_npp*.h5');

% First get username (works on Mac too), space at end of command?

custom_path = '/strow/Matlab/Grib';

% Replace ~ with appropriate full path
if computer == 'MACI64'
   custom_path = fullfile('/Users/',custom_path);
elseif computer == 'GLNXA64'
   custom_path = fullfile('/home/',custom_path);
end

fnum = 30;

addpath /asl/rtp_prod/cris/utils
addpath /asl/rtp_prod/cris/readers
addpath /asl/matlib/aslutil
addpath /asl/matlib/rtptools
addpath ~/Matlab/Grib

[head hattr prof pattr] = sdr2rtp_h5(fullfile(fdir,a(fnum).name));
[prof,head]=fill_ecmwf(prof,head);
head.pfields = 5;
%[head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);
[head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);
[head,hattr,prof,pattr]=rtpadd_emis_DanZhou(head,hattr,prof,pattr);

rtpwrite('/home/strow/test.rtp',head,hattr,prof,pattr)

 

