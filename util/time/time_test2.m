%
% test utc2tai and tai2utc at leap second boundaries
%
% note utc2tai and tai2utc return NaN for pre-1972 dates
%

% leap second boundaries
d{1}  = '31 dec 1971 23:59:59';
d{2}  =  '1 jan 1972 00:00:00';

d{3}  = '30 jun 1972 23:59:59';
d{4}  =  '1 jul 1972 00:00:00';

d{5}  = '31 dec 1979 23:59:59';
d{6}  =  '1 Jan 1980 00:00:00';

d{7}  = '30 jun 1983 23:59:59';
d{8}  =  '1 jul 1983 00:00:00';

d{9}  = '31 dec 2008 23:59:59';
d{10} =  '1 Jan 2009 00:00:00';

d{11} = '30 jun 2012 23:59:59';
d{12} =  '1 jul 2012 00:00:00';

n = length(d);
dnum = ones(n, 1) * NaN;
for i = 1 : n
  dnum(i) = datenum(d{i});
end

utc58 = (dnum - datenum('1 jan 1958')) * 24 * 60 * 60;

tai58 = utc2tai(utc58);

% show leap second
tai58 - utc58

utc58b = tai2utc(tai58);

% snow residuals
utc58 - utc58b

