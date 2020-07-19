% 
% datetime test, datetime to TAI
%

% regular matlab UTC times
U58 = datetime('1958-01-01');
U93 = datetime('1993-01-01');
Uxx = datetime('2012-02-01 00:02:10');

% UTC times with leap seconds
L58 = datetime('1958-01-01T00:00:00.000Z','timezone','UTCLeapSeconds');
L93 = datetime('1993-01-01T00:00:00.000Z','timezone','UTCLeapSeconds');
Lxx = datetime('2012-02-01T00:02:10.000Z','timezone','UTCLeapSeconds');

% try to get Lxx from Uxx
Qxx = Uxx;
Qxx.TimeZone = 'UTCLeapSeconds'
Qxx.Year   = Uxx.Year;
Qxx.Month  = Uxx.Month;
Qxx.Day    = Uxx.Day;
Qxx.Hour   = Uxx.Hour;
Qxx.Minute = Uxx.Minute;
Qxx.Second = Uxx.Second;

isequal(Lxx, Qxx)

% TAI times
T93 = 12784 * 86400 + 27;         % 1 jan 1993 00:00:00
Txx = 19754 * 86400 + 34 + 130;   % 1 feb 2012 00:02:10

dU = seconds(U93 - U58);   % regular Matlab UTC difference
dL = seconds(L93 - L58);   % UTC difference with UTCLeapSeconds
dQ = seconds(Qxx - L58);   % UTC difference with UTCLeapSeconds

T93 - dU    % the matlab time diff is wrong by 27 seconds
T93 - dL    % the matlab time diff is wrong by 10 seconds
Txx - dQ    % the matlab time diff is wrong by 10 seconds

