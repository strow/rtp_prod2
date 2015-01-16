addpath /asl/matlib/h4tools
addpath /asl/matlib/aslutil
addpath /asl/rtp_prod/cris/unapod
addpath /asl/matlab2012/aslutil

fdir = '/asl/s1/sergio/CRIS_CCAST/sdr60_hr/2014/338';

fn(1,:) = 'SDR_d20141204_t1520231.rtp';
fn(2,:) = 'SDR_d20141204_t1528231.rtp';
fn(3,:) = 'SDR_d20141204_t1536230.rtp';
fn(4,:) = 'SDR_d20141204_t1544230.rtp';
fn(5,:) = 'SDR_d20141204_t1600229.rtp';
fn(6,:) = 'SDR_d20141204_t1608228.rtp';
fn(7,:) = 'SDR_d20141204_t1616228.rtp';
fn(8,:) = 'SDR_d20141204_t1944216.rtp';
fn(9,:) = 'SDR_d20141204_t1952216.rtp';
fn(10,:) = 'SDR_d20141204_t2000215.rtp';
fn(11,:) = 'SDR_d20141204_t2008215.rtp';
fn(12,:) = 'SDR_d20141204_t2016214.rtp';
fn(13,:) = 'SDR_d20141204_t2024214.rtp';
fn(14,:) = 'SDR_d20141204_t2032214.rtp';
fn(15,:) = 'SDR_d20141204_t2040213.rtp';
fn(16,:) = 'SDR_d20141204_t2048213.rtp';
fn(17,:) = 'SDR_d20141204_t2056212.rtp';
fn(18,:) = 'SDR_d20141204_t2104212.rtp';
fn(19,:) = 'SDR_d20141204_t2112211.rtp';
fn(20,:) = 'SDR_d20141204_t2120211.rtp';
fn(21,:) = 'SDR_d20141204_t2128210.rtp';
fn(22,:) = 'SDR_d20141204_t2136210.rtp';
fn(23,:) = 'SDR_d20141204_t2144209.rtp';
fn(24,:) = 'SDR_d20141204_t2152209.rtp';
fn(25,:) = 'SDR_d20141204_t2200209.rtp';
fn(26,:) = 'SDR_d20141204_t2208208.rtp';
fn(27,:) = 'SDR_d20141204_t2216208.rtp';

%SDR_d20141204_t2040213.rtp
fn1 = (650:0.625:1095)';
fn2 = (1210:0.625:1750)';
fn3 = (2155:0.625:2550)';
fnall = [fn1; fn2; fn3];

%kk = input('file index  ')
load coast
for i=15
   fdir = '/Users/strow/Desktop';
   fnf = fullfile(fdir,fn(i,:));

  [h,ha,p,pa]=rtpread(fnf);
  [fcris, ix, isdr] = intersect(fnall,h.vchan);


% % Find guard channels
%   k =  find(h.ichan > 1305);
% % Replace robs1 guard channels with calcs
%   p.robs1(k,:) = p.rcalc(k,:);
%   clear k

% % Apodize robs with hamming
%   robs_ham = boxg4_to_ham(h.ichan,p.robs1);
  bto = real(rad2bt(fcris,p.robs1(isdr,:)));
  btc = rad2bt(fcris,p.rcalc(isdr,:));
  bias = bto-btc;

% Get clear obs
  ch = find (fcris > 1231,1);
  kobs  = find( abs(bias(ch,:)+0.1)  < 0.5 & p.landfrac == 0);

  length(kobs)

  figure
  h1 = subplot(211);
  plot(fcris,nanmean(bto(:,kobs),2));
  hold on;grid;
  plot(fcris,nanmean(btc(:,kobs),2));

  h2 = subplot(212);
  plot(fcris,nanmean(bias(:,kobs),2));
  adjust21(h1,h2,'even')
  hold on;grid
  plot(fcris,nanstd(bias(:,kobs),0,2));
  hl = legend('Bias','Std');

  figure;
  plot(p.rlon(kobs),p.rlat(kobs),'+')
  hold on;
  plot(long,lat,'k-')

% % Unapodize rcalcs
% ru        = crisg4_unapod(1:1329,rcal_mean');
% bt_calu   = rad2bt(fcris,ru);

end
