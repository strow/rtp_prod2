function [h, p] = strip_prof(head, prof)
% STRIP_PROF Strips early iasi rtp run output down to basic rtp struct
%
% 

p.udef = prof.udef;
p.iudef = prof.iudef;
p.rlat = prof.rlat;
p.rlon = prof.rlon;
p.rtime = prof.rtime;
p.robsqual = prof.robsqual;
p.satzen = prof.satzen;
p.satazi = prof.satazi;
p.solzen = prof.solzen;
p.solazi = prof.solazi;
p.zobs = prof.zobs;
p.atrack = prof.atrack;
p.xtrack = prof.xtrack;
p.ifov = prof.ifov;
p.robs1 = prof.robs1;
p.pobs = prof.pobs;
p.upwell = prof.upwell;

h.ptype = 0;
h.pfields = 4;

h.vchan = head.vchan;
h.ichan = head.ichan;
h.nchan = head.nchan;


%% ****end function strip_prof****