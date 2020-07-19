% 
% datetime test, try TAI to datetime
%

% Set a TAI time
tai = 12784 * 86400 + 27;         % 1 jan 1993 00:00:00
tai = 19754 * 86400 + 34 + 130;   % 1 feb 2012 00:02:10

% regular UTC base time
U58 = datetime('1958-01-01');
U58.Second = tai;
datestr(U58)

% UTC base with leap seconds
L58 = datetime('1958-01-01T00:00:00.000Z','timezone','UTCLeapSeconds');
L58.Second = tai;
datestr(L58)

% try the conversions
dt = L58;
dt.TimeZone = '';
dt.Year   = L58.Year;
dt.Month  = L58.Month;
dt.Day    = L58.Day;
dt.Hour   = L58.Hour;
dt.Minute = L58.Minute;
dt.Second = L58.Second;
datestr(dt)

