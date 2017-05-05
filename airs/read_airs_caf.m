function sda = read_airs_caf(sDate, nGran)
%
% inputs: sDate: A date string such as '2014/05/01'
%         nGran: the granule number (standard 1 to 240 if available).
%
% output: sda: a numerical structure of arrays containing available fields:-
%         sda.rtim double[90x135]; seconds AIRS TAI-1993
%         sda.rlat & sda.rlon both single [90x135] units:degrees;
%         sda.asc single [1x135] flag; ascending = 1, descending = 0;
%         sda.ra single [2645x90x135] the clean and filled AIRS radiance. (stnd units);
%
% Dependencies: hdfsw.m (standard matlab library)
%
% Assumptions: Location of AIRS CAF data files, which are granule sized, 
%              and exact syntax of file name.
%
% Notes: the AIRS CAF files are hdf-4.
%

% process date string
posYrs = [2002:2015];
posMns = [1:12];
syr = sDate(1:4);  smn = sDate(6:7); sdy = sDate(9:10);
junk = ismember(num2str(posYrs), syr); if(isempty(~find(junk))) fprintf('invalid year\n'); end
junk = ismember(num2str(posMns), smn); if(isempty(~find(junk))) fprintf('invalid month\n'); end
junk = ismember([1:31], str2num(sdy)); if(isempty(~find(junk))) fprintf('invalid day\n'); end
nyr  = str2num(syr); nmn = str2num(smn);  ndy = str2num(sdy);
junk = sprintf('%4d/%02d/%02d',nyr-1,12,31);
jday = datenum(sDate)-datenum(junk);  clear junk;           % needed for CRIS directory

% process granule number
if(nGran < 1 || nGran > 240) fprintf('Invalid granule number\n'); exit; end
sGran = sprintf('%03d',nGran);

% Hard wire path and granule dimensions
xtrk  = 90; atrk = 135; nobs  = 90*135;
fd    = ['/asl/data/airs/L1C/' syr '/' sprintf('%03d',jday) '/'];

% construct file name and check existence:
fstr   = ['AIRS.',syr,'.',smn,'.',sdy,'.',sGran,'.L1C.hdf'];
fstat  = exist([fd fstr]);
if(fstat == 0) fprintf('Sorry, this file does not exist\n'); exit; end


% Assign variables to be read in.
sda = struct;

% open file and attach swath
file_id   = hdfsw('open',[fd fstr],'read');
  if file_id == 0; disp('Error opening hdf file'); end;
swid      = hdfsw('attach',file_id,'mySwath');
  if swid == 0; disp('Error attaching swath'); end;

[junk,s]  = hdfsw('readfield',swid,'Time',[],[],[]);    % [90 x 135]
  if s == -1; disp('Error reading time');end;
sda.rtim  = double(junk); clear junk;
[junk,s]  = hdfsw('readfield',swid,'Latitude',[],[],[]);
  if s == -1; disp('Error reading latitude');end;
sda.rlat  = single(junk); clear junk;
[junk,s]  = hdfsw('readfield',swid,'Longitude',[],[],[]);
  if s == -1; disp('Error reading longitude');end;
sda.rlon  = single(junk); clear junk;
[junk,s]  = hdfsw('readfield',swid,'ScanNode',[],[],[]);   % [135 x 1]
  if s == -1; disp('Error reading scan node');end;
clear tmp;
for i=1:numel(junk) 
  if junk(i) == 65; tmp(i) = 1; end       % ascending
  if junk(i) == 68; tmp(i) = 0; end       % descending
end
sda.asc  = single(tmp);  clear tmp;       % [1 x 135]
[junk,s] = hdfsw('readfield',swid,'Radiance',[],[],[]);
  if s == -1; disp('Error reading radiance');end;
%%%sda.ra  = reshape( single(junk), 2645,nobs);  clear junk;
sda.ra  = single(junk); clear junk;

% Close L1C granule file
s = hdfsw('detach',swid);
  if s == -1; disp('Swatch detach error: L1c');end;   
s = hdfsw('close',file_id);
  if s == -1; disp('File close error: L1c');end;

end
