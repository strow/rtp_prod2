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
% can be found for other instrument with something like
%     chan = find(h.vchan >= 1231,1);
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


% plot histogram of latitudes coresponding to random obs selection
% (should follow roughly cos(latitude)
figure(4)
histogram(randlat)
hold on
amp = 800;
plot([-90:0.5:90], amp*cos([-90:0.5:90]*(2*pi)/360), 'k-', 'LineWidth', 2)
hold off
xlabel('Latitude')
title('CrIS random latitude sampling')
print -dpng '~/ToTransfer/20150218-rand-lathist.png'

keyboard
