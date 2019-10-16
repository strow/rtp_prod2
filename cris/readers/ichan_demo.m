%
% ichan_demo -- get sarta ichan and vchan values for CrIS
%

addpath /asl/packages/ccast/source
addpath /asl/packages/ccast/motmsc/rtp_sarta

opt1 = struct;
opt1.user_res = 'hires';    % 'hires' or 'lowres'
opt1.inst_res = 'hires3';   % doesn't matter here
wlaser = 773.1307;          % doesn't matter here

[instLW, userLW] = inst_params('LW', wlaser, opt1);
[instMW, userMW] = inst_params('MW', wlaser, opt1);
[instSW, userSW] = inst_params('SW', wlaser, opt1);

ng = 2;   % number of guard channels you are using  
sg = 4;   % number of guard channels sarta was built with

vchan = cris_vchan(ng, userLW, userMW, userSW);

n1 = round((userLW.v2 - userLW.v1) / userLW.dv) + 1;
n2 = round((userMW.v2 - userMW.v1) / userMW.dv) + 1;
n3 = round((userSW.v2 - userSW.v1) / userSW.dv) + 1;

ichan = cris_ichan(ng, sg, n1, n2, n3);

