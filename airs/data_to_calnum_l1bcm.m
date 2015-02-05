function [calnum, cstr] = data_to_calnum_l1bcm(freq, nen, ...
   calchansummary, calflag, rtime, granule_number);

% function [calnum, cstr] = data_to_calnum_l1bcm(freq, nen, ...
%    calchansummary, calflag, rtime, granule_number);
%
% Convert various AIRS calibration data into an 8-bit number.
% WARNING: v5 l1b_cal_subset files lack calflag; should appear in v6
%
% Input:
%    freq           - [2378 x 1] nominal channel freqs
%    nen            - [2378 x 241] noise equivalent radiance
%    calchansummary - [2378 x 241] granule channel summary
%    calflag        - [2378 x nobs] scanline calibration flags
%    rtime          - [1 x nobs] observation time {sec since 0z 01 Jan 1993}
%    granule_number - [1 x nobs] granule number {0-240}
%       Note: two partial granules at 0z and 24z.
%
% Output
%    calnum         - [2378 x nobs] 8-bit calibration number
%                        bits1-4 = NEdT(@250K) lookup table index-1 {0-15}
%                        bit5    = A side detector {0=off, 1=on}
%                        bit6    = B side detector {0=off, 1=on}
%                        bits7-8 = calflag & calchansummary
%                           {0=OK, 1=DCR, 2=moon, 3=other}
%    cstr           - [string] character string describing calnum
%
% Hint: calnum <= 63 are OK, calnum <= 127 are DCR-only,
%       calnum =< 191 are moon-only, calnum >= 192 are other
%

% Created: 02 Jun 2010, Scott Hannon
% Update: 17 Nov 2010, S.Hannon - change bits 7 & 8 from two separate binary
%    flags to one combined 2-bit number.  Replace "ng" with hardcoded 241, and
%    add error trap to ensure that value.
% Update: 14 Jun 2011, S.Hannon - bug fix for NEdT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Spectral calibration filename and TAI time when A/B weight changes
caldir = 'calprops';
calfiles = {'airs_cal_prop_2002_08_30.txt', ...
            'airs_cal_prop_2003_01_10.txt', ...
            'airs_cal_prop_2003_11_19.txt'};
caltimes = [304853040, 316342920, 343376580]; % start times
% Note: caltimes might be any hour of the day but usually are around 9z

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NeDT lookup table table; 16th value for no-data or greater than max
%           1    2    3    4    5    6    7    8   9  10  11  12  13  14  15
lutable = [0.08 0.12 0.15 0.20 0.25 0.30 0.35 0.4 0.5 0.6 0.7 0.8 1.0 2.0 4.0];
%
% Note: cstr must include the substring "NEdT[" followed by 16 numbers.
cstr =[ 'bits1-4=NEdT[0.08 0.12 0.15 0.20 0.25 0.30 0.35 0.4 0.5 0.6 0.7' ...
  ' 0.8 1.0 2.0 4.0 nan]; bit5=Aside[0=off,1=on]; bit6=Bside[0=off,1=on];' ...
  ' bits7-8=calflag&calchansummary[0=OK, 1=DCR, 2=moon, 3=other]' ];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Check input
if (nargin ~= 6)
   error('Unexpected number of input arguments')
end
d = size(freq);
if (length(d) ~= 2 | d(1) ~= 2378 | d(2) ~= 1)
   error('Unexpected dimensions for argument "freq"');
end
d = size(nen);
if (length(d) ~= 2 | d(1) ~= 2378 | d(2) ~= 241)
   error('Unexpected dimensions for argument "nen"');
end
d = size(calchansummary);
if (length(d) ~= 2 | d(1) ~= 2378 | d(2) ~= 241)
   error('Unexpected dimensions for argument "calchansummary"');
end
d = size(calflag);
if (length(d) ~= 2 | d(1) ~= 2378)
   error('Unexpected dimensions for argument "calflag"');
end
nobs = d(2);
d = size(rtime);
if (length(d) ~= 2 | max(d) ~= nobs | min(d) ~= 1)
   error('Unexpected dimensions for argument "rtime"');
end
d = size(granule_number);
if (length(d) ~= 2 | max(d) ~= nobs | min(d) ~= 1)
   error('Unexpected dimensions for argument "granule_number"');
end


% Create output array
calnum = zeros(2378,nobs);


% Convert granule_number to nobs index
gind = round(granule_number + 1); % exact integer 1:241


% Convert nen to nedt
ibad = find(nen < 0);
nen(ibad) = 1;
r250 = bt2rad(freq,250);
nedt = rad2bt(freq,r250*ones(1,241)+nen) - 250;
nedt(ibad ) = 100; % bigger than last lookup table value
nedt = nedt(:,gind); % convert [2378 x 241] to [2378 x nobs]
%
% Convert nedt to lookup table index-1
for ii=15:-1:1
   ind = find(nedt < lutable(ii));
%wrong   calnum(ind) = ii;
   calnum(ind) = ii-1;
end
ind = find(nedt > lutable(15));
calnum(ind) = 15;
clear r250 nedt ibad


% Set A/B detector bits
mtime = mean(rtime);
ind = 0;
for ii=1:length(caltimes)
   if (mtime > caltimes(ii))
      ind = ii;
   end
end
if(exist(calfiles{ii},'file'))
  calprop = load(calfiles{ii});
elseif(exist([caldir '/' calfiles{ii}],'file'))
  calprop = load([caldir '/' calfiles{ii}]);
else
  error(['Can find airs_cal_prop file ' calfiles{ii}]);
end
ab = calprop(:,4); % 0=opt, 1=A, 2=B
bit5 = zeros(2378,nobs);
bit6 = zeros(2378,nobs);
ii = find(ab == 0);
bit5(ii,:) = 16; % 2^4
bit6(ii,:) = 32; % 2^5
ii = find(ab == 1);
bit5(ii,:) = 16;
ii = find(ab == 2);
bit6(ii,:) = 32;
calnum = calnum + bit5 + bit6;
clear bit5 bit6 ab


% Assign bits7-8 calflag&calchansummary
% Values: OK={b7=0,b8=0}, DCR={b7=1,b8=0}, moon={b7=0,b8=1}, other={b7=1,b8=1}
bits78 =  192*ones(2378,nobs); % 2^6=64 + 2^7=128
ix = find(calchansummary(:,gind) == 0); % no calchansummary problems
i0 = ix( find(calflag(ix) == 0) );  % no problems
if (length(i0) > 0)
   bits78(i0) = 0;
end
i0 = ix( find(calflag(ix) == 8) );  % DCR-only
if (length(i0) > 0)
   bits78(i0) = 64;
end
i0 = ix( find(calflag(ix) == 4) );  % moon-only
if (length(i0) > 0)
   bits78(i0) = 128;
end
calnum = calnum + bits78;
clear bits78 ix i0
%
calnum = uint8( round(calnum) );  % exact integer


%%% end of file %%%
