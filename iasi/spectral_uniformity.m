function [sflag, dbt757, dbt820, dbt960, dbt1231, dbt2140] = ...
   spectral_uniformity( sfile, uflag)

% function [sflag, dbt757, dbt820, dbt960, dbt1231, dbt2140] = ...
%    spectral_uniform( IASI_Radiances, uflag, dbtmax757, dbtmax820, ...
%    dbtmax960, dbtmax1231, dbtmax2140);
%
% For each FOV in "n" do a spatial uniformity test over the 2x2 IASI
% pixels.  BT are computed for window channels in various spectral
% regions, and one non-window region near 757 cm^-1. The BT of all
% four IASI pixels in the FOV are compared
% using the first element of the dbtmax arrays.  Next, the BT of
% those pixels with true uflag are compared with the second element
% of the dbtmax arrays.
% This version uses four subsets of window channels near 820, 960,
% 1231, and 2140 cm^-1, and one non-window near 757 cm^-1.
% The dbtmax are assumed to be for 280 K and converted to drmax to
% account for the change in the noise level with temperature.
%
% Input:
%    IASI_Radiances = [n x 4 x 8461] IASI spectral radiance
%    uflag      = [n x 4] imager uniform flag (0=not, 1=uniform)
% presets:
%    dbtmax757  = [1 x 2]  757 cm^-1 max delta BT, (1)=all, (2)=uflag 1
%    dbtmax820  = [1 x 2]  820 cm^-1 max delta BT, (1)=all, (2)=uflag 1
%    dbtmax960  = [1 x 2]  960 cm^-1 max delta BT, (1)=all, (2)=uflag 1
%    dbtmax1231 = [1 x 2] 1231 cm^-1 max delta BT, (1)=all, (2)=uflag 1
%    dbtmax2140 = [1 x 2] 2140 cm^-1 max delta BT, (1)=all, (2)=uflag 1
%
% Output:
%    sflag   = [n x 4] spectral uniform flag (0=not, 1=uniform)
%    dbt757  = [n x 2]  757 cm^-1 delta BT, (1)=all, (2)=uflag 1
%    dbt820  = [n x 2]  820 cm^-1 delta BT, (1)=all, (2)=uflag 1
%    dbt960  = [n x 2]  960 cm^-1 delta BT, (1)=all, (2)=uflag 1
%    dbt1231 = [n x 2] 1231 cm^-1 delta BT, (1)=all, (2)=uflag 1
%    dbt2140 = [n x 2] 2140 cm^-1 delta BT, (1)=all, (2)=uflag 1
%
% Dependencies:
%  a. readl1c_epsflip_all.m
%  b. ttorad.m, radtot.m
%
% Created: 05 April 2007, Scott Hannon - based on imager_uniform.m
% Update: 10 April 2007, Scott Hannon - pass in IASI_Radiances rather than read
%    it; generic leading dimension "n" (not maditory b=660).
% Update: 29 March 2010, S.Hannon - add 757 region non-window test; adjust
%    dbtmax from T=280 to T=BTobs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit this section as needed


% netcdf tools

% Expected data dimensions
npixfov = 4;    % number of IASI "pixels" per FOV (ie 2x2 = 4)
nchan = 8461;   % number of IASI channels
% Note: an IASI "FOV" is composed of a 2x2 square of IASI "pixels".

% tiny default BT to plug in when radiance is negative
bttiny=150;

% Indices of channels for testing assuming f=645:0.25:2760 and ind(1)
% corresponds to f(1).
ind757 = [435 442 447 448 453 454];
ind820 = [692 693 694 698 699 700 704 705 706 710 713 716];
ind960 = [1172 1173 1178 1179 1180 1188 1193 1194 1195 1222 ...
          1223 1229 1230 1248 1249 1250 1254 1255 1256 1262 ...
          1263 1264 1265 1266 1270 1271 1272 1276 1277 1278];
ind1231 = [2238 2239 2240 2345 2346 2347 2348 2349];
ind2140 = [5954 5955 5956 5957 5992 5993 5994 5995 5996];

% Value to use for "no data"
nodata = -999;

% spectral_uniform757 arguments
  dbtmax757  = [2, 1];
  dbtmax820  = [2, 1];
  dbtmax960  = [2, 1];
  dbtmax1231 = [2, 1];
  dbtmax2140 = [3, 2];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% load the granule
data = readl1c_epsflip_all(sfile);

d = size(data.IASI_Radiances);
if (length(d) ~= 3 | d(2) ~= npixfov | d(3) ~= nchan)
   error('unexpected dimensions for IASI_Radiances')
end
nax = d(1);
IASI_Radiances = data.IASI_Radiances;
clear data;

% Declare empty output variables
sflag   = zeros(nax,npixfov);
dbt757  = nodata*ones(nax,2);
dbt820  = nodata*ones(nax,2);
dbt960  = nodata*ones(nax,2);
dbt1231 = nodata*ones(nax,2);
dbt2140 = nodata*ones(nax,2);


% WARNING! this routine channel freqs are as follows:
fchan = (645:0.25:2760)'; %'
%
f757  = mean( fchan(ind757 ) );
f820  = mean( fchan(ind820 ) );
f960  = mean( fchan(ind960 ) );
f1231 = mean( fchan(ind1231) );
f2140 = mean( fchan(ind2140) );


% Tiny radiances
rtiny = ttorad(fchan,bttiny);
rtiny757  = mean( rtiny(ind757 ) );
rtiny820  = mean( rtiny(ind820 ) );
rtiny960  = mean( rtiny(ind960 ) );
rtiny1231 = mean( rtiny(ind1231) );
rtiny2140 = mean( rtiny(ind2140) );
clear rtiny fchan


% Convert dbtmax to drmax
drmax757  = ttorad(f757, 280+dbtmax757)  - ttorad(f757, 280);
drmax820  = ttorad(f820, 280+dbtmax820)  - ttorad(f820, 280);
drmax960  = ttorad(f960, 280+dbtmax960)  - ttorad(f960, 280);
drmax1231 = ttorad(f1231,280+dbtmax1231) - ttorad(f1231,280);
drmax2140 = ttorad(f2140,280+dbtmax2140) - ttorad(f2140,280);


% Loop over the FOVs
sflag4 = sflag;
for ii = 1:nax

   % Find IASI pixels with true uflag
   ipu = find(uflag(ii,:) == 1);
   npu = length(ipu);

   if (npu > 0)
      % Spectral radiances for current FOV
      radall = squeeze(IASI_Radiances(ii,:,:))'; %' [8461 x 4]

      % Non-window 757 cm^-1 channels
      rad  = radall(ind757,:); % [n757 x 4]
      ibad = find(rad < rtiny757);
      if (length(ibad) > 0)
         rad(ibad)=rtiny757;
      end
      rad = mean( rad ); % [1 x 4]
      r   = max(rad); % [1 x 1]
      bt  = radtot(f757,rad);
      dbtmax = radtot(f757,r + drmax757) - radtot(f757,r);
      dbt757(ii,1) = max(bt) - min(bt);
      if (dbt757(ii,1) < dbtmax(1))
         if (npu > 1)
            dbt757(ii,2) = max(bt(ipu)) - min(bt(ipu));
            if (dbt757(ii,2) < dbtmax(2))
               sflag4(ii,ipu) = sflag4(ii,ipu) + 1;
            end
         else
            sflag4(ii,ipu) = sflag4(ii,ipu) + 1;
         end
      end


      % 820 cm^-1 channels
      rad = radall(ind820,:); % [n820 x 4]
      ibad = find(rad < rtiny820);
      if (length(ibad) > 0)
         rad(ibad)=rtiny820;
      end
      rad = mean( rad ); % [1 x 4]
      r = max(rad); % [1 x 1]
      bt = radtot(f820,rad);
      dbtmax = radtot(f820,r + drmax820) - radtot(f820,r);
      dbt820(ii,1) = max(bt) - min(bt);
      if (dbt820(ii,1) < dbtmax(1))
         if (npu > 1)
            dbt820(ii,2) = max(bt(ipu)) - min(bt(ipu));
            if (dbt820(ii,2) < dbtmax(2))
               sflag4(ii,ipu) = sflag4(ii,ipu) + 1;
            end
         else
            sflag4(ii,ipu) = sflag4(ii,ipu) + 1;
         end
      end

      % 960 cm^-1 channels
      rad = radall(ind960,:); % [n960 x 4]
      ibad = find(rad < rtiny960);
      if (length(ibad) > 0)
         rad(ibad)=rtiny960;
      end
      rad = mean( rad ); % [1 x 4]
      r = max(rad); % [1 x 1]
      bt = radtot(f960,rad);
      dbtmax = radtot(f960,r + drmax960) - radtot(f960,r);
      dbt960(ii,1) = max(bt) - min(bt);
      if (dbt960(ii,1) < dbtmax(1))
         if (npu > 1)
            dbt960(ii,2) = max(bt(ipu)) - min(bt(ipu));
            if (dbt960(ii,2) < dbtmax(2))
               sflag4(ii,ipu) = sflag4(ii,ipu) + 1;
            end
         else
            sflag4(ii,ipu) = sflag4(ii,ipu) + 1;
         end
      end

      % 1231 cm^-1 channels
      rad  = radall(ind1231,:); % [n1231 x 4]
      ibad = find(rad < rtiny1231);
      if (length(ibad) > 0)
         rad(ibad)=rtiny1231;
      end
      rad = mean( rad ); % [1 x 4]
      r   = max(rad); % [1 x 1]
      bt  = radtot(f1231,rad);
      dbtmax = radtot(f1231,r + drmax1231) - radtot(f1231,r);
      dbt1231(ii,1) = max(bt) - min(bt);
      if (dbt1231(ii,1) < dbtmax(1))
         if (npu > 1)
            dbt1231(ii,2) = max(bt(ipu)) - min(bt(ipu));
            if (dbt1231(ii,2) < dbtmax(2))
               sflag4(ii,ipu) = sflag4(ii,ipu) + 1;
            end
         else
            sflag4(ii,ipu) = sflag4(ii,ipu) + 1;
         end
      end

      % 2140 cm^-1 channels
      rad = radall(ind2140,:); % [n2140 x 4]
      ibad = find(rad < rtiny2140);
      if (length(ibad) > 0)
         rad(ibad)=rtiny2140;
      end
      rad = mean( rad ); % [1 x 4]
      r   = max(rad); % [1 x 1]
      bt  = radtot(f2140,rad);
      dbtmax = radtot(f2140,r + drmax2140) - radtot(f2140,r);
      dbt2140(ii,1) = max(bt) - min(bt);
      if (dbt2140(ii,1) < dbtmax(1))
         if (npu > 1)
            dbt2140(ii,2) = max(bt(ipu)) - min(bt(ipu));
            if (dbt2140(ii,2) < dbtmax(2))
               sflag4(ii,ipu) = sflag4(ii,ipu) + 1;
            end
         else
            sflag4(ii,ipu) = sflag4(ii,ipu) + 1;
         end
      end

   end % in npu

end % for nax

% Assign sflag=1 where sflag4=5 (ie passed all 5 tests)
ii = find(sflag4 == 5);
sflag(ii) = 1;

%%% end of function %%%
