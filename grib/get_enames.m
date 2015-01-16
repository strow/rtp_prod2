function enames = get_enames(mtime);

% Provides the core part of an ECMWF grib file name
% To get the full file name (minus year, month) you need to:
%  1. prepend 'UAD'
%  2. postpend '0001'
% These operations can be done right before reading the file

% Modify to give full ename, so can do era as well?

% Assign the fixed forecast creation times, indices are forecast times in 
% hour + 1; hour = [0 3 6 9 12 15 19 21]
fhrstr(1,:)  = '0000';
fhrstr(4,:)  = '0000';
fhrstr(7,:)  = '0600';
fhrstr(10,:) = '0000';
fhrstr(13,:) = '1200';
fhrstr(16,:) = '1200';
fhrstr(19,:) = '1800';
fhrstr(22,:) = '1200';

% round to get 8 forecast hours per day
rmtime = round(mtime*8)/8;

timestr = datestr(rmtime,'yyyymmddhh');
ystr = timestr(:,1:4);
mstr = timestr(:,5:6);
dstr = timestr(:,7:8);
hstr = timestr(:,9:10);

% index for fhrstr
h = str2num(hstr);

enames = [mstr dstr fhrstr(h+1,:) mstr dstr hstr];
enames = cellstr(enames);

