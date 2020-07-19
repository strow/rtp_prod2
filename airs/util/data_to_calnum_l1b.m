function [calnum, cstr] = data_to_calnum_l1b(tai, freq, nen, ...
   calchansummary, calflag);

% function [calnum, cstr] = data_to_calnum_l1b(tai, freq, nen, ...
%    calchansummary, calflag);
%
% Convert various AIRS L1B granule data into an 8-bit "calnum".
%
% REQUIRES:
% /home/sbuczko1/git/rtp_prod2/util
%
% Input:
%    tai            - [1  x 1] granule mean time {sec since 0z 01 Jan 1993}
%       Note: used to select appropriate calibration properties file
%    freq           - [2378 x 1] nominal channel freqs
%    nen            - [2378 x 1] noise equivalent radiance
%    calchansummary - [2378 x 1] granule channel summary
%    calflag        - [2378 x 135] or [2378 x 45] scanline calibration flags
%
% Output
%    calnum         - [2378 x 135] or [2378 x 45] 8-bit calibration number
%                        bits1-4 = NEdT(@250K) lookup table index-1 {0-15}
%                           See "cstr" for lookup table
%                        bit5    = A side detector {0=off, 1=on}
%                        bit6    = B side detector {0=off, 1=on}
%                        bits7-8 = calflag & calchansummary
%                           {0=OK, 1=DCR, 2=moon, 3=other}
%    cstr           - [string] character string describing calnum
%
% Hint: calnum <= 63 are OK, calnum <= 127 are DCR-only,
%       calnum =< 191 are moon-only, calnum >= 192 are other
% 

% Created: 16 Nov 2010, Scott Hannon - created from data_to_calnum_l1bcm
%  Update: 20 Apr 2011, Paul Schou - added support for L2 data, 2378 x 45
%  Update: 14 Jun 2011, S.Hannon - bug fix for NEdT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Spectral calibration filename and TAI time when A/B weight changes
caldir = '/asl/matlab/airs/utils';
caldir = '/asl/matlab2012/airs/utils';
calfiles = {'airs_cal_prop_2002_08_30.txt', ...
            'airs_cal_prop_2003_01_10.txt', ...
            'airs_cal_prop_2003_11_19.txt'};
caltimes = [304853040, 316342920, 343376580]; % start times


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NeDT lookup table table; 16th value for no-data or greater than max
%           1    2    3    4    5    6    7    8   9  10  11  12  13  14  15
lutable = [0.08 0.12 0.15 0.20 0.25 0.30 0.35 0.4 0.5 0.6 0.7 0.8 1.0 2.0 4.0];
%
% Note: cstr must include the substring "NEdT[" followed by 16 numbers.
cstr =[ 'bits1-4=NEdT[0.08 0.12 0.15 0.20 0.25 0.30 0.35 0.4 0.5 0.6 0.7' ...
  ' 0.8 1.0 2.0 4.0 nan]; bit5=Aside[0=off,1=on]; bit6=Bside[0=off,1=on];' ...
  ' bits7-8=calflag&calchansummary [0=OK, 1=DCR, 2=moon, 3=other]' ];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Check input
if (nargin ~= 5)
   error('Unexpected number of input arguments')
end
d = size(tai);
if (length(d) ~= 2 | max(d) ~= 1 | min(d) ~= 1)
   error('Unexpected dimensions for argument "tai"');
end
d = size(freq);
if (length(d) ~= 2 | d(1) ~= 2378 | d(2) ~= 1)
   error('Unexpected dimensions for argument "freq"');
end
d = size(nen);
if (length(d) ~= 2 | d(1) ~= 2378 | min(d) ~= 1)
   error('Unexpected dimensions for argument "nen"');
end
d = size(calchansummary);
if (length(d) ~= 2 | d(1) ~= 2378 | min(d) ~= 1)
   error('Unexpected dimensions for argument "calchansummary"');
end
d = size(calflag);
if (length(d) ~= 2 | d(1) ~= 2378 | ~(d(2) == 135 | d(2) == 45))
   error('Unexpected dimensions for argument "calflag"');
end


% Create output array
calnum = zeros(size(calflag));


% Convert nen to nedt
ibad = find(nen < 0);
nen(ibad) = 1;
r250 = bt2rad(freq,250);
nedt = rad2bt(freq,r250 + nen) - 250;
nedt(ibad) = 100; % bigger than last lookup table value
clear r250 ibad


% Save nedt to calnum as bounding lookup table index-1
for ii=15:-1:1
   ind = find(nedt < lutable(ii));
%wrong   calnum(ind,:) = ii;
   calnum(ind,:) = ii-1;
end
ind = find(nedt > lutable(15));
calnum(ind,:) = 15;
clear nedt


% Set A/B detector bits
ind = 0;
for ii=1:length(caltimes)
   if (tai > caltimes(ii))
      ind = ii;
   end
end
calprop = load([caldir '/' calfiles{ii}]);
ab = calprop(:,4); % 0=opt, 1=A, 2=B
%
% Default is opt
calnum = calnum + 48; % opt = A+B = 16+32
% Find A-only
ii = find(ab == 1);
calnum(ii,:) = calnum(ii,:) - 32;
% Find B-only
ii = find(ab == 2);
calnum(ii,:) = calnum(ii,:) - 16;
clear ab calprop


% Assign bits7-8 calflag&calchansummary
% Values: OK={b7=0,b8=0}, DCR={b7=1,b8=0}, moon={b7=0,b8=1}, other={b7=1,b8=1}
bit7 =  64*ones(size(calflag)); % 2^6
bit8 = 128*ones(size(calflag)); % 2^7
ix = find(calchansummary*ones(1,size(calflag,2)) == 0); % no calchansummary problems
i0 = ix( find(calflag(ix) == 0) );  % no problems
if (length(i0) > 0)
   bit7(i0) = 0;
   bit8(i0) = 0;
end
i0 = ix( find(calflag(ix) == 8) );  % DCR-only
if (length(i0) > 0)
   bit8(i0) = 0;
end
i0 = ix( find(calflag(ix) == 4) );  % moon-only
if (length(i0) > 0)
   bit7(i0) = 0;
end
calnum = calnum + bit7 + bit8;
clear bit7 bit8 ix i0
%
calnum = uint8( round(calnum) );


%%% end of file %%%
