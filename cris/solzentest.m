function solzentest

% load path for rtpread
addpath('~/git/rtp_prod2/util');

crisdir = '/asl/s1/sbuczko1/testoutput/2015/049';
crisfiles = dir(fullfile(crisdir, '*.rtp'));

numcfiles = length(crisfiles);

fprintf(1, '>> Found %d rtp files in directory %s\n', numcfiles, ...
        crisdir);

fprintf(1, '>>* Concatenating granule solzen values\n');

tsolzen = [];
trlat = [];
trlon = [];
trobs1 = [];
tiudef = [];
for i=1:numcfiles
    [h,ha,p,pa] = rtpread(fullfile(crisdir, crisfiles(i).name));

    ssolzen = cat(2, tsolzen, p.solzen);
    tsolzen = ssolzen;
    srlat = cat(2, trlat, p.rlat);
    trlat = srlat;
    srlon = cat(2, trlon, p.rlon);
    trlon = srlon;
    srobs1 = cat(2, trobs1, p.robs1);
    trobs1 = srobs1;
    siudef = cat(2, tiudef, p.iudef(1,:));
    tiudef = siudef;
    
end

freq = h.vchan;
sbt = rad2bt(freq, srobs1);

% use 1231 wavenumber channel for plotting
%     chan = 1291 AIRS
%     chan = 754  CrIS
chan = 754;

% find clear obs
clearind = find(tiudef == 1);
clearbt = sbt(chan, clearind);
clearlat = srlat(clearind);
clearlon = srlon(clearind);
clearsolzen = ssolzen(clearind);

% plot day (solzen < 90)
dayind = find(clearsolzen < 90);
figure(2)
simplemap(clearlat(dayind), clearlon(dayind), clearbt(dayind), 'auto', ...
          0.5);
title('Daytime clear 2015/02/18')
print('-dpng', '~/ToTransfer/20150218_daytime_clear.png');

% $$$ % plot night (solzen > 90)
% $$$ nightind = find(clearsolzen > 90);
% $$$ figure(3)
% $$$ simplemap(clearlat(nightind), clearlon(nightind), clearbt(nightind), 'auto', ...
% $$$           0.5);

% find random obs
randind = find(tiudef == 8);
randbt = sbt(chan, randind);
randlat = srlat(randind);
randlon = srlon(randind);
randsolzen = ssolzen(randind);

% plot day (solzen < 90)
dayind = find(randsolzen < 90);
figure(3)
simplemap(randlat(dayind), randlon(dayind), randbt(dayind), 'auto', ...
          0.5);
title('Daytime random 2015/02/18')
print('-dpng', '~/ToTransfer/20150218_daytime_random.png');

% $$$ % plot night (solzen > 90)`
% $$$ nightind = find(randsolzen > 90);
% $$$ figure(4)
% $$$ simplemap(randlat(nightind), randlon(nightind), randbt(nightind), 'auto', ...
% $$$           0.5);
% $$$ title('Nighttime random 2015/02/18')

keyboard
