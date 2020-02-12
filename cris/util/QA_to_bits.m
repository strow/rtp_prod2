function [QAbitsLW,QAbitsMW,QAbitsSW,qual] = QA_to_bits(QA);

% function [QAbitsLW,QAbitsMW,QAbitsSW,qual] = QA_to_bits(QA);
%
% Convert QA structure data into three 20bit QAbits
% arrays, one for each of the three CrIS bands (LW,MW,SW).
% Each QA data field is reshaped and/or expanded as needed
% into a 1-dimension vector of length nobs = 9*30*natrack.
%
% Input:
%     QA       -  QA structure returned by "cris_sdr_QAflags.m"
%
% Output:
%    QAbitsLW  -  int32 [1 x nobs] LongWave band QA bits
%    QAbitsMW  -  int32 [1 x nobs] MediumWave band QA bits
%    QAbitsSW  -  int32 [1 x nobs] ShortWave band QA bits
%    qual      -  int32 [1 x nobs] 3-bit quality flag (0=good,1=bad)
%                    with bit1=band1, bit2=band2, bit3=band3
%

% Created: 09 Dec 2011, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Required fields
req_fields = ...
 {'Data_Gap', ...
  'Timing_Sequence_Error', ...
  'Lambda_Monitored_Quality', ...
  'Invalid_Instrument_Temperatures', ...
  'Excess_Thermal_Drift',...
  'Neon_Cal_Flag_Set',...
  'Invalid_Geolocation',...
  'FCE_Correction_Failed',...
  'Day_Night',...
  'Invalid_RDR_Data',...
  'Many_FCE_Detection',...
  'Bit_Trim_Failed',...
  'Lunar_Intrusion',...
  'SDR_Quality',...
  'Invalid_Radiometric_Calibration',...
  'Invalid_Spectral_Calibration'};

% Corresponding start and end bits for output
sbit = [1 2 3 4 5 6 11 16 17 18 19 20 7  9 12 14];
ebit = [1 2 3 4 5 6 11 16 17 18 19 20 8 10 13 15];

% Original CrIS SDR QF number
QFnum = [1 1 1 1 1 1 3 4 4 4 4 4 2 3 3 3];

% Day_Night bit (as assigned above)
daynightbit = sbit(9);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
if (nargin ~= 1)
   error('Unexpected number of input arguments')
end
if (~isstruct(QA))
   error('Input argument QA is not a structure as expected')
end
fnames = fieldnames(QA);
nreq = length(req_fields);
natrack = -1;
nobs = -1;
for ii=1:nreq
   if (~isfield(QA,req_fields{ii}))
      error(['QA is missing required field: ' req_fields{ii}])
   end
   if (QFnum(ii) == 1 & natrack < 0)
      eval(['natrack = length(QA.' req_fields{ii} ');']);
      nobs = 9*30*natrack;
   end
end
if (natrack < 1)
   error('Unexpected value determined for natrack')
end


% Declare work arrays
bitsLW = zeros(1,nobs,'uint32');
bitsMW = zeros(1,nobs,'uint32');
bitsSW = zeros(1,nobs,'uint32');


% Loop over the fields
for ii=1:nreq
   % Get current data
   eval(['data = uint8(QA.' req_fields{ii} '(:)'');']);  % [1 X N]
   nbits = 1 + ebit(ii) - sbit(ii);
   ibad = find(data < 0 | data > -1 + 2^nbits );
   if (length(ibad) > 0)
      error(['Unexpected data values for field: ' req_fields{ii}])
   end
   %
   % Prepare QF1 data
   if (QFnum(ii) == 1)
      % QF1 fields are [natrack x 1]
      data = repmat(data,3*9*30,1);
      data = reshape(data,3,nobs);
   end
   %
   % Prepare QF2 data
   if (QFnum(ii) == 2)
      % QF2 field is [3 x 9 x natrack]
      data = reshape(data,3*9,natrack);
      data2 = zeros(3*9*30,natrack,'uint8');
      for jj=1:natrack
         data2(:,jj) = reshape(repmat(data(:,jj),1,30),3*9*30,1);
      end
      data = reshape(data2,3,nobs);
   end
   %
   % prepare QF3 data
   if (QFnum(ii) == 3)
      % QF3 fields are [3 x 9 x 30 x natrack]
      data = reshape(data,3,nobs);
   end
   %
   % Prepare QF4 data
   if (QFnum(ii) == 4)
      % QF4 fields are [3 x 9 x 30 x natrack]
      data = reshape(data,3,nobs);
   end
   %
   % assign bits
   ibit = sbit(ii);
   bitsLW = bitset(bitsLW,ibit,bitget(data(1,:),1));
   bitsMW = bitset(bitsMW,ibit,bitget(data(2,:),1));
   bitsSW = bitset(bitsSW,ibit,bitget(data(3,:),1));
   if (nbits == 2)
      ibit = ebit(ii);
      bitsLW = bitset(bitsLW,ibit,bitget(data(1,:),2));
      bitsMW = bitset(bitsMW,ibit,bitget(data(2,:),2));
      bitsSW = bitset(bitsSW,ibit,bitget(data(3,:),2));
   end
end


% Convert work bit arrays to output arrays
QAbitsLW = int32(bitsLW);
QAbitsMW = int32(bitsMW);
QAbitsSW = int32(bitsSW);
%
% Set the Day/Night indicator bit to 0 to now meaning no problem
bitsLW = bitset(bitsLW,daynightbit,0);
bitsMW = bitset(bitsMW,daynightbit,0);
bitsSW = bitset(bitsSW,daynightbit,0);
%
qual = zeros(1,nobs,'int32');
ibad = find(bitsLW > 0);
qual(ibad) = qual(ibad) + 1;
ibad = find(bitsMW > 0);
qual(ibad) = qual(ibad) + 2;
ibad = find(bitsSW > 0);
qual(ibad) = qual(ibad) + 4;

%%% end of function %%%
