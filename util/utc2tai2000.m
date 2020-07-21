function [tai] = utc2tai2000(year, month, day, dhour);

%
% function [tai] = utc2tai2000(year, month, day, dhour);
%
% Convert UTC time to approximate seconds since 1 Jan 2000 (IASI tai time)
%
% Input:
%    year  : (1 x n) 4 digit integer year
%    month : (1 x n) 1 or 2 digit integer month
%    day   : (1 x n) 1 or 2 digit integer day
%    dhour : (1 x n) decimal hour
%
% Output:
%    tai : (1 x n) IASI TAI time (seconds since 00:00 1 Jan 2000)
%

% Created: 23 October 2002 Scott Hannon
% Update: 28 Nov 2007, S.Hannon - "2000" variant created
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%
% Assign basic info

% Number of days per month
%      1  2  3  4  5  6  7  8  9 10 11 12
ndpm=[31 28 31 30 31 30 31 31 30 31 30 31];

% Allowed years
allyears=2000:2099;
nall=length(allyears);

% Leap years every 4 years except century years unless divisible by 400
leapyears=2000:4:2099;


%%%
% Check input

if ( ndims(year) > 2 | min(size(year)) ~= 1 )
   error('year must be a scaler or 1-D vector')
end
if ( ndims(month) > 2 | min(size(month)) ~= 1 )
   error('month must be a scaler or 1-D vector')
end
if ( ndims(day) > 2 | min(size(day)) ~= 1 )
   error('day must be a scaler or 1-D vector')
end
if ( ndims(dhour) > 2 | min(size(dhour)) ~= 1 )
   error('dhour must be a scaler or 1-D vector')
end

[irow,icol]=size(year);
n=length(year);
iyear=round(year);
if ( max(abs(year - iyear)) > 0.01 | min(iyear) < 2000 | max(iyear) > 2099 )
   error('year must be an integer 2000 to 2099')
end
if (irow == n)
   iyear=iyear'; %'
end

[ir,ic]=size(month);
if (max([ir,ic]) ~= n)
   error('month must be the same length array as year')
end
imonth=round(month);
if (abs(month - imonth) > 0.01 | imonth < 1 | imonth > 12)
   error('month must be an integer 1 to 12');
end
if (ir == n)
   imonth=imonth'; %'
end

ly=ismember(iyear,leapyears);
maxday=ndpm(imonth);
ii=find( imonth == 2 & ly == 1);
maxday(ii)=29;
[ir,ic]=size(day);
if (max([ir,ic]) ~= n)
   error('day must be the same length array as year')
end
if (ir == n)
   iday=round(day)';
   if (max(abs(day' - iday)) > 0.01 | min(iday) < 1 | max(iday - maxday) > 0)
      error('day must be a valid day for month & year');
   end
else
   iday=round(day);
   if (max(abs(day - iday)) > 0.01 | min(iday) < 1 | max(iday - maxday) > 0)
      error('day must be a valid day for month & year');
   end
end

[ir,ic]=size(dhour);
if (max([ir,ic]) ~= n)
   error('dhour must be the same length array as year')
end
if (ir == n)
   xhour=dhour'; %'
else
   xhour=dhour;
end
if (xhour < 0 | xhour > 24)
   error('dhour must be a real number between 0 and 24')
end


%%%
% Create TAI lookup tables for years and months
%
% Number of days in all allowed years
ndiy=365*ones(1,nall);
ii=find( ismember(allyears,leapyears) == 1);
ndiy(ii)=366;
%
% Seconds per day
spd=24*60*60;
%
% Seconds since 1 Jan 2000 at start of each year
junk=[0, ndiy(1:(nall-1))]; % elapsed days since 1 Jan 2000
taiyear=cumsum(junk)*spd;
%
% Seconds since start of year at start of each month (non-leap year)
junk=[0, ndpm(1:11)]; % elapsed days of year at start of each month
taimonth=cumsum(junk)*spd;


%%%
% Calc TAI time for all dates
ii=iyear - 2000 + 1;  % index for taiyear
tai=taiyear(ii) + taimonth(imonth) + (iday-1)*spd + xhour*3600;
%
% Do correction to taimonth for leap day if needed
ii=find(ly == 1 & imonth > 2);
tai(ii)=tai(ii) + spd;


%%% end of function %%%
