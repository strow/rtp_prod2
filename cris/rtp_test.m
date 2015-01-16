%
% rtp_test -- basic high level tests of ccast2rtp
%

% high res test file
sfile = '/asl/data/cris/ccast/sdr60_hr/2013/240/SDR_d20130828_t0310579.mat';

% low res test file
% sfile = '/asl/data/cris/ccast/sdr60/2014/002/SDR_d20140102_t2053431.mat';

% set the number of guard channels
nguard = 4;

% do the test
[head, hattr, prof, pattr] = ccast2rtp(sfile, nguard);

% sample radiance plot
figure(1); clf
[m, nobs] = size(prof.robs1);
k = max(1, floor(nobs/20));
v = head.vchan;
r = prof.robs1(:, 1:k:nobs);
plot(v, real(rad2bt(v, r)))
title('sample CrIS RTP data')
xlabel('wavenumber')
ylabel('BT in K')
grid on; zoom on

% ichan and vchan
figure(2); clf
subplot(2,1,1)
plot(head.ichan)
grid on; zoom on
title('ichan')
ylabel('index')
subplot(2,1,2)
plot(head.vchan)
title('vchan')
xlabel('index')
ylabel('wavenum')
grid on; zoom on

% ichan guard indices
figure(3); clf
n = head.nchan;
ic = 1 : n;
ix = (n - 7 * nguard) : n;
subplot(2,1,1)
plot(ic(ix), head.ichan(ix));
title('ichan guard chan index')
ylabel('index')
grid on; zoom on

subplot(2,1,2)
plot(ic(ix), v(head.ichan(ix)));
title('ichan guard chan freq')
xlabel('index')
ylabel('wavenum')
grid on; zoom on

