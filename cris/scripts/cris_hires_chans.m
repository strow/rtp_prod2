function [n1,n2,n3,userLW,userMW,userSW, ichan_hires] = cris_hires_chans();

addpath /asl/packages/ccast/motmsc/rtp_sarta
addpath /asl/packages/ccast/source

wlaser = 773.1307;
opts.resmode = 'hires2';

[instLW, userLW] = inst_params('LW', wlaser,opts);
n1 = (userLW.v2-userLW.v1)/userLW.dv + 1;

[instMW, userMW] = inst_params('MW', wlaser,opts);
n2 = (userMW.v2-userMW.v1)/userMW.dv + 1;

[instSW, userSW] = inst_params('SW', wlaser,opts);
n3 = (userSW.v2-userSW.v1)/userSW.dv + 1;

ichan_hires = cris_ichan(2, 4, n1, n2, n3);



