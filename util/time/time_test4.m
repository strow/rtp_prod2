% 
% test utc2tai, tai2utc, dtime2tai, tai2dtime
%

% datevec times for tests
d1 = [2001 7 15 13 20 30;
      2001 7 15 13 20 31;
      2001 7 15 13 20 32;
      2001 7 15 13 20 33];

d2 = [2012 6 30 23 59 58;
      2012 6 30 23 59 59;
      2012 7  1  0  0  0;
      2012 7  1  0  0  0;
      2012 7  1  0  0  1];

% TAI, base is 15 Jul 2001 13:20:30
t1 = (daydif(1958, 2001)+196-1)*86400 + 13*3600 + 20*60 + (30:33)' + 32;

% TAI, base is 30 Jun 2012 23:59:58
t2 = (daydif(1958, 2012)+182-1)*86400 + 23*3600 + 59*60 + (58:62)' + 34;

% IET test times
e1 = t1 * 1e6;
e2 = t2 * 1e6;

% AIRS test times
a1 = t1 - (12784 * 86400 + 27);
a2 = t2 - (12784 * 86400 + 27);

% matlab datenums
n1 = datenum(d1);
n2 = datenum(d2);

% identical values

isequal(n1, tai2dnum(t1))
isequal(n2, tai2dnum(t2))

isequal(n1, airs2dnum(a1))
isequal(n2, airs2dnum(a2))

isequal(n1, iet2dnum(e1))
isequal(n2, iet2dnum(e2))

isequal(n1, utc2dnum(tai2utc(t1)))
isequal(n2, utc2dnum(tai2utc(t2)))

isequal(n1, airs2dnum(tai2airs(t1)))
isequal(n2, airs2dnum(tai2airs(t2)))

isequal(n1, utc2dnum(tai2utc(iet2tai(dnum2iet(n1)))))
isequal(n2, utc2dnum(tai2utc(iet2tai(dnum2iet(n2)))))

isequal(n1, iet2dnum(tai2iet(airs2tai(dnum2airs(n1)))))
isequal(n2, iet2dnum(tai2iet(airs2tai(dnum2airs(n2)))))

% small residuals

% note that if we start with TAI time, go to UTC, and come back, 
% the TAI residual will be off by 1 for a leap second, since two
% distinct TAI values are being mapped to one UTC value

dnum2tai(n1) - t1
dnum2tai(n2) - t2

dnum2airs(iet2dnum(tai2iet(airs2tai(a1)))) - a1
dnum2airs(iet2dnum(tai2iet(airs2tai(a2)))) - a2




