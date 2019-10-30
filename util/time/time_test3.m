% 
% test utc2tai, tai2utc, dtime2tai, tai2dtime
%

%-------------------------------
% compare utc2tai and dtime2tai
%-------------------------------

% date vector for tests
% d1 = [1994  3 13  7 33 13];
  d1 = [2015  6  3 23 59  9;
        2015  7  3 23 59  9];

% small residual
dtime2tai2(datetime(d1)) - utc2tai(dnum2utc(datenum(d1)))  

%-------------------------------
% compare tai2utc and tai2dtime
%-------------------------------

% TAI time for tests
t1 = 19754 * 86400 + 34 + 120 + (0:3);  % 1 feb 2012 00:02:00 base

datenum(tai2dtime(t1)) - utc2dnum(tai2utc(t1))

%----------------------
% back and forth tests
%----------------------

utc2tai(tai2utc(t1)) - t1

% small residual
dtime2tai(tai2dtime(t1)) - t1

% date number for tests
dn1 = datenum('5 sep 1995 04:15:50');

datenum(datetime(dn1, 'ConvertFrom', 'datenum')) - dn1

utc2dnum(dnum2utc(dn1)) - dn1

%--------------------------
% utc2tai performance test
%--------------------------

% date vector for tests
d2 = ones(60, 1) * [1994  3 13  7 33 13];
d2(:, 5) = 0:59;

dnum2  = datenum(d2);
utc2   = dnum2utc(dnum2);
dtime2 = datetime(d2);

rms(utc2tai(dnum2utc(dnum2)) -  dtime2tai(dtime2))
rms(utc2tai(dnum2utc(dnum2)) -  dtime2tai2(dtime2))

return

profile on

for i = 1 : 1000
% t1 = utc2tai(utc2);
  t1 = utc2tai(dnum2utc(dnum2));
  t2 = dtime2tai2(dtime2);
end

profile report

