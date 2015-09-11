addpath /asl/packages/ccast/motmsc/rtp_sarta
addpath /asl/packages/ccast/source

wlaser = 773.1307;
opts.resmode = 'hires2'

[inst, user] = inst_params('LW', wlaser,opts);
n1 = (user.v2-user.v1)/user.dv + 1

[inst, user] = inst_params('MW', wlaser,opts);
n2 = (user.v2-user.v1)/user.dv + 1

[inst, user] = inst_params('SW', wlaser,opts);
n3 = (user.v2-user.v1)/user.dv + 1

n1+n2+n3

ichan_hires = cris_ichan(2, 4, n1, n2, n3);

ichan_hires(1:4)

