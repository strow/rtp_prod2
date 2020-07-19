function [cflag, retsst, dbtq, dbt820, dbt960, dbtsst] = spectral_clear( ...
   sfile, lsea, modsst, sflag, dbtqmin, dbt820max, dbt960max, dbtsstmax)

% function [cflag, retsst, dbtq, dbt820, dbt960, dbtsst] = spectral_clear(...
%    IASI_Radiances, Satellite_Zenith, lsea, modsst, sflag, dbtmaxq, ...
%    dbtmaxg, dbtmaxsst);
%
% For each of the "n" (2x2) FOVs, so do a spectral clear test on each of
% the four individual IASI pixels. Does a quick & dirty retrieval of SST
% and compares to expected SST.  Predicts BT of 820 and 960 cm^-1 region
% channels using other windown channels and compares to measured BT.
% Checks the BT difference between on-line and off-line of weak water
% lines in the 920 cm^-1 window region.
% Version3
%
% Input:
%    sfile for IASI_Radiances   = [n x 4 x 8461] IASI spectral radiances
%    Satellite_Zenith = [n x 4] satellite zenith angle
%    lsea      = [n x 4] sea? (0=false, 1=true)
%    modsst    = [n x 4] model/expected SST
%    sflag     = [n x 4] spectral uniform flag (0=not, 1=uniform)
%    dbtqmin   = [1 x 1] "q" lower trop water min |delta BT|
%    dbt820max = [1 x 1] cirrus 820 cm^-1 max |delta BT|
%    dbt960max = [1 x 1] dust 960 cm^-1 max |delta BT|
%    dbtsstmax = [1 x 1] SST max |delta BT|
%
% Output:
%    cflag   = [n x 4] spectral clear flag (0=not, 1=clear)
%    retsst  = [n x 4] retrieved SST
%    dbtq    = [n x 4] "q" delta BT
%    dbt820  = [n x 4] cirrus 820 cm^-1 delta BT
%    dbt960  = [n x 4] dust 960 cm^-1 delta BT
%    dbtsst  = [n x 4] SST delta BT.
% Note: retsst and dbtsst are calculated for all pixels, but are
% tested only if lsea=1.
%
% Dependencies:
%  a. readl1c_epsflip_all.m
%  b. ttorad.m radtot.m
%

% Created: 09 April 2007, Scott Hannon - based on spectral_uniform.m
% Update: 10 April 2007, Scott Hannon - pass in IASI_Radiance rather than read
%    it; generic leading dimension "n" (not manditory n=660); add "lsea".
% Update: 08 June 2007, Scot Hannon - version3
% Update: 15 Jan 2008, S.Hannon - Shift chan ID by -140 so id1=645 cm^-1
% Update: 27 Jun 2008, S.Hannon - fix typo bug (i"d1203"); set dbtq to dbtq1206
% Update: 28 Apr 2010, S.Hannon - modify dbtsst test to also check land; add
%    retsst threshold checks (to remove very cold surfaces)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit this section as needed


% netcdf tools

% Expected data dimensions
npixfov = 4;      % number of IASI "pixels" per FOV (ie 2x2 = 4)
nchan   = 8461;   % number of IASI channels
% Note: an IASI "FOV" is composed of a 2x2 square of IASI "pixels".

% tiny default BT to plug in when radiance is negative
bttiny = 150;

% Channel ID (id1=645 cm^-1)
id820 = [ 685  686  687  688  689  690  691  692  693  694  695  696 ...
          697  698  699  700  701  702  703  704  705  706  707  708 ...
          709  710  711  712  713  714  715  716  717  718  719];
id960 = [1172 1173 1178 1179 1180 1188 1193 1194 1195 1222 1223 1229 ...
         1230 1248 1249 1250 1254 1255 1256 1262 1263 1264 1265 1266 ...
         1270 1271 1272 1276 1277 1278];
id1130= [1912 1913 1914 1915 1916 1917 1918 1919 1920 1921 1922 1923 ...
         1924 1925 1926 1927 1928 1929 1930 1931 1932 1933 1934 1935 ...
         1936 1937 1938 1939 1940 1941 1942 1943 1944 1945 1946 1947 ...
         1948 1949 1950 1951 1952 1953 1954 1955 1956 1957 1958];
id1203= [2223 2229 2233 2239]; % window
id1206= [2245 2246]; % weak on-line water
id1231= [2331 2332 2333 2345 2346 2347 2348 2349 2350 2351 2357 2358 ...
         2359 2360 2361 2362];
% note: dbtq1206 = bt1203 - bt1206;
ind820  = id820;
ind960  = id960;
ind1130 = id1130;
ind1203 = id1203;
ind1206 = id1206;
ind1231 = id1231;


%%% old channel ID (id141=645 cm^-1)
% Note: ID numbers are for our fast model starting at 610 cm^-1;
% L1C data starts at 645 cm^-1 (ie 140 points away).
id820 = [ 825   826   827   828   829   830   831   832   833   834 ...
          835   836   837   838   839   840   841   842   843   844 ...
          845   846   847   848   849   850   851   852   853   854 ...
          855   856   857   858   859];
id960 = [1312 1313 1318 1319 1320 1328 1333 1334 1335 1362 1363 1369 ...
         1370 1388 1389 1390 1394 1395 1396 1402 1403 1404 1405 1406 ...
         1410 1411 1412 1416 1417 1418];
id1130 = [2052 2053 2054 2055 2056 2057 2058 2059 2060 2061 2062 2063 ...
          2064 2065 2066 2067 2068 2069 2070 2071 2072 2073 2074 2075 ...
          2076 2077 2078 2079 2080 2081 2082 2083 2084 2085 2086 2087 ...
          2088 2089 2090 2091 2092 2093 2094 2095 2096 2097 2098];
id1203 = [2363 2369 2373 2379]; % window
id1206 = [2385 2386]; % weak on-line water
id1231 =[2471 2472 2473 2485 2486 2487 2488 2489 2490 2491 2497 2498 ...
         2499 2500 2501 2502];
% note: dbtq1206 = bt1203 - bt1206;
%
ind820  = id820  - 140;
ind960  = id960  - 140;
ind1130 = id1130 - 140;
ind1203 = id1203 - 140;
ind1206 = id1206 - 140;
ind1231 = id1231 - 140;
%%%


% note: secang=secant(satzen)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Asst = [bt1203; bt1206; bt1231; secang; secang.^2; dbtq1206.*secang]'; %'
% Estimate generally good to within 1.3 K
Xsst = [ 6.8961558e+00  2.3604725e-01 -6.1224598e+00 ...
        -3.4485738e+00  1.7574343e+00  1.0474673e-01];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A820 = [bt1130; bt1203; bt1206; bt1231; secang; secang.*dbtq1206]'; %' cirrus
% Estimate generally good to with 1.5 K
X820 = [ 1.6562100e-01 -3.7578118e+00  1.3157679e-01 ...
         4.4618721e+00 -8.3660578e-02  8.1200438e-02];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A960 = [bt1203; bt1206; bt1231; secang; secang.*dbtq1206]'; %' dust
% Estimate generally good to within 1.0 K
X960 = [-1.6927485e+00 -1.4785473e-01  2.8399888e+00 ...
         2.1071471e-01  3.9929060e-02];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Value for "no data"
nodata = -999;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load the granule
data = readl1c_epsflip_all(sfile);

d = size(data.IASI_Radiances);
if (length(d) ~= 3 | d(2) ~= npixfov | d(3) ~= nchan)
   error('unexpected dimension of IASI_Radiances')
end
nax = d(1);
IASI_Radiances   = data.IASI_Radiances;
Satellite_Zenith = data.Satellite_Zenith;
clear data;

d = size(Satellite_Zenith);
if (length(d) ~= 2 | d(1) ~= nax | d(2) ~= npixfov)
   error('unexpected dimensions for Satellite_Zenith data')
end
secang = 1 ./ cos(Satellite_Zenith*pi/180); % secant angle


% Declare empty output variables
cflag  = zeros(nax,npixfov,'int32');
retsst = nodata*ones(nax,npixfov);
dbtq   = nodata*ones(nax,npixfov);
dbt820 = nodata*ones(nax,npixfov);
dbt960 = nodata*ones(nax,npixfov);
dbtsst = nodata*ones(nax,npixfov);


% WARNING! assumes channel freqs are as follows:
fchan = (645:0.25:2760)'; %'
%
f820  = mean( fchan(ind820 ) );
f960  = mean( fchan(ind960 ) );
f1130 = mean( fchan(ind1130) );
f1203 = mean( fchan(ind1203 ) );
f1206 = mean( fchan(ind1206) );
f1231 = mean( fchan(ind1231) );


% Tiny radiances
rtiny = ttorad(fchan,bttiny);
rtiny820  = mean( rtiny(ind820 ) );
rtiny960  = mean( rtiny(ind960 ) );
rtiny1130 = mean( rtiny(ind1130) );
rtiny1203 = mean( rtiny(ind1203) );
rtiny1206 = mean( rtiny(ind1206) );
rtiny1231 = mean( rtiny(ind1231) );


% Loop over the 2x2 FOVs
cflag4 = cflag;
for ii = 1:nax

   % Find pixels with true sflag
   ips = find(sflag(ii,:) == 1);
   nps = length(ips);

   if (nps > 0)
      % Spectral radiances for the current FOV
      radall = squeeze(IASI_Radiances(ii,:,:))'; %' [8461 x 4]


      % 820 cm^-1 channels
      rad = radall(ind820,:); % [n820 x 4]
      ibad = find(rad < rtiny820);
      if (length(ibad) > 0)
         rad(ibad)=rtiny820;
      end
      rad = mean( rad ); % [1 x 4]
      bt820 = radtot(f820,rad);

      % 960 cm^-1 channels
      rad = radall(ind960,:); % [n960 x 4]
      ibad = find(rad < rtiny960);
      if (length(ibad) > 0)
         rad(ibad)=rtiny960;
      end
      rad = mean( rad ); % [1 x 4]
      bt960 = radtot(f960,rad);

      % 1130 cm^-1 channels
      rad = radall(ind1130,:); % [n1130 x 4]
      ibad = find(rad < rtiny1130);
      if (length(ibad) > 0)
         rad(ibad)=rtiny1130;
      end
      rad = mean( rad ); % [1 x 4]
      bt1130 = radtot(f1130,rad);

      % 1203 cm^-1 channels
      rad = radall(ind1203,:); % [n1203 x 4]
      ibad = find(rad < rtiny1203);
      if (length(ibad) > 0)
         rad(ibad)=rtiny1203;
      end
      rad = mean( rad ); % [1 x 4]
      bt1203 = radtot(f1203,rad);

      % 1206 cm^-1 channels
      rad = radall(ind1206,:); % [n1206 x 4]
      ibad = find(rad < rtiny1206);
      if (length(ibad) > 0)
         rad(ibad)=rtiny1206;
      end
      rad = mean( rad ); % [1 x 4]
      bt1206 = radtot(f1206,rad);

      % 1231 cm^-1 channels
      rad = radall(ind1231,:); % [n1231 x 4]
      ibad = find(rad < rtiny1231);
      if (length(ibad) > 0)
         rad(ibad)=rtiny1231;
      end
      rad = mean( rad ); % [1 x 4]
      bt1231 = radtot(f1231,rad);

      dbtq1206 = bt1203 - bt1206;
      dbtq(ii,:) = dbtq1206;

      % cirus: affects bt820 most strongly
      A820 = [bt1130; bt1203; bt1206; bt1231; secang(ii,:); ...
              secang(ii,:).*dbtq1206];
      calc_bt820 = X820*A820;
      dbt820(ii,:) = bt820 - calc_bt820;


      % dust: affects bt960 most strongly
      A960 = [bt1203; bt1206; bt1231; secang(ii,:); secang(ii,:).*dbtq1206];
      calc_bt960 = X960*A960;
      dbt960(ii,:) = bt960 - calc_bt960;


      % SST
      Asst = [bt1203; bt1206; bt1231; secang(ii,:); secang(ii,:).^2; ...
              secang(ii,:).*dbtq1206];
      retsst(ii,:) = Xsst*Asst;
      dbtsst(ii,:) = modsst(ii,:) - retsst(ii,:);


%%% No "q" test
%      % Test #1: "q"
%      adbt = abs( dbtq(ii,:) );
%      iok = find( adbt > dbtqmin );
%      if (length(iok) > 0)
%         cflag4(ii,iok) = cflag4(ii,iok) + 1;
%      end
%%%

      % Test #2: cirrus
      adbt = abs( dbt820(ii,:) );
      iok = find( adbt < dbt820max );
      if (length(iok) > 0)
	  cflag4(ii,iok) = cflag4(ii,iok) + 1;
      end

      % Test #3: dust
      adbt = abs( dbt960(ii,:) );
      iok = find( adbt < dbt960max );
      if (length(iok) > 0)
	  cflag4(ii,iok) = cflag4(ii,iok) + 1;
      end


%%% replaced 28 Apr 2010
%      % Test #4: SST
%      adbt = abs( dbtsst(ii,:) );
%      iok = find( adbt < dbtsstmax & lsea(ii,:) == 1 );
%      if (length(iok) > 0)
%	  cflag4(ii,iok) = cflag4(ii,iok) + 1;
%      end
%      %
%      % Not-sea pixels automatically pass
%      inotsea = find( lsea(ii,:) == 0 );
%      if (length(inotsea) > 0)
%	  cflag4(ii,inotsea) = cflag4(ii,inotsea) + 1;
%%%%
%%          dbtsst(ii,inotsea) = nodata;
%%%%
%      end
%%% 28 Apr 2010 replacement code
      % Test #4: SST
      % Sea
      adbt = abs( dbtsst(ii,:) );
      iok = find( adbt < dbtsstmax & lsea(ii,:) == 1 & ...
         retsst(ii,:) > 270.0 );
      if (length(iok) > 0)
	  cflag4(ii,iok) = cflag4(ii,iok) + 1;
      end
      %
      % Not-sea
      iok = find( adbt < dbtsstmax*2.5 & lsea(ii,:) == 0 & ...
         retsst(ii,:) > 258.0 );
      if (length(iok) > 0)
	  cflag4(ii,iok) = cflag4(ii,iok) + 1;
      end
%%%

   end % in npu

end % for nax

% Assign cflag=1 where cflag4=3 (ie passed all 3 tests)
%iiu = find(cflag4 == 4);
ii4  = find(cflag4 >= 1);     %  "q" test is commented out
iis  = find(sflag  == 1);
iiu  = intersect(iis, ii4);
cflag(iiu) = 1;
%cflag = cflag4;

%%% end of function %%%
