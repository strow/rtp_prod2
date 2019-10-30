% 
% datetime test, show how time differences fail
%

% regular matlab UTC times
U58 = datetime('1958-01-01');
U93 = datetime('1993-01-01');

% UTC times with leap seconds
L58 = datetime('1958-01-01T00:00:00.000Z','timezone','UTCLeapSeconds');
L93 = datetime('1993-01-01T00:00:00.000Z','timezone','UTCLeapSeconds');

% TAI time for 1993
T93 = 12784 * 86400 + 27;

dU = seconds(U93 - U58);   % regular Matlab UTC difference
dL = seconds(L93 - L58);   % UTC difference with UTCLeapSeconds

T93 - dU    % the matlab time diff is wrong by 27 seconds
T93 - dL    % the matlab time diff is wrong by 10 seconds

% try TAI as a datetime param
Q58 = datetime(1958,1,1,0,0,0);    % identical to U58
Q93 = datetime(1958,1,1,0,0,T93)   % gives 01-Jan-1993 00:00:27

