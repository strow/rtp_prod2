%
% NAME
%   utc2tai - take UTC to TAI by adding leap seconds
%
% SYNOPSIS
%   tai58 = utc2tai(utc58, sfile)
%
% INPUTS
%   utc58  - UTC seconds since 1 Jan 1958
%   sfile  - optional file of leap seconds
%
% OUTPUTS
%   tai58  - TAI seconds since 1 Jan 1958
%
% DISCUSSION
%   TAI time is UT1-TAI aka TAI 58, true seconds since 1 Jan 1958.
%   UTC time as used here is seconds/day * days since 1 Jan 1958,
%   where seconds/day is fixed at 24 * 60 * 60.  UTC time is behind
%   TAI by a slowly increasing number of leap seconds.  The table 
%   of leap-seconds used here is from [3] and starts at 1 Jan 1900.
%  
%   The input utc58 can be any array shape, and the output tai58
%   will match.  The function loops on elements of utc58 and so is
%   relatively slow.
%
%   UTC time was defined as starting 1 Jan 1972 with a ten second
%   offset from TAI.  UTC time before then is not well-defined, as
%   there is no standard way of assigning the leap seconds.
%
% REFERENCES
%   [1] http://tycho.usno.navy.mil/leapsec.html
%   [2] http://en.wikipedia.org/wiki/Leap_second
%   [3] http://www.ietf.org/timezones/data/leap-seconds.list
%
% AUTHOR
%  H. Motteler, 26 Jan 2015
%

function tai58 = utc2tai(utc58, sfile)

% default leap-seconds file
if nargin == 1
  sfile = '/asl/packages/ccast/inst_data/leap-seconds.list';
end

% read the leap seconds file
fid = fopen(sfile, 'r');
if fid ~= -1
  leap_tab = cell2mat(textscan(fid, '%d64%d64', 'commentstyle', '#'));
  leap_tab = double(leap_tab);
  fclose(fid);
else
  error(sprintf('can not open %s\n', sfile))
end

% zero row for pre 1972 dates
leap_tab = [[0, 0]; leap_tab];

% seconds from 1900 to 1958
tai_base = 1830297600;

% initialize output
tai58 = utc58 * NaN;

% loop on elements 
for i = 1 : numel(utc58)

  if isnan(utc58(i)), continue, end

  % find utc58 in the first column
  j = max(find(leap_tab(:, 1) <= tai_base + utc58(i)));

  % add the leap seconds
  tai58(i) = utc58(i) + leap_tab(j, 2);

end
