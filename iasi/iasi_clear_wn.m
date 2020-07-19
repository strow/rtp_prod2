function [iflags, bto1232, btc1232] = iasi_clear_wn(head, prof, icheck);

% function [iflags, bto1232, btc1232] = xfind_clear_wn(head, prof, icheck);
%
% Do clear tests for the specified FOV/profile indices and
% return test results as bit flags.  Designed for use with
% Hamming apodized radiances.
%
% Input:
%    head - RTP header structure with fields ichan and vchan
%    prof - RTP profiles structure with fields rcalc, robs1, landfrac
%    icheck - [1 x ncheck] indices to check
%
% Output:
%    iflags - [1 x ncheck] bit flags for the following tests:
%       1 = abs(BTobs-BTcal) at 1232 wn > threshold
%       2 = cirrus detected
%       4 = dust/ash detected
%       8 = marine boundary layer cloud detected
%    bto1232 - [1 x ncheck] BTobs of 1232 wn
%    btc1232 - [1 x ncheck] BTcal of 1232 wn
%

% Created: 13 April 2011, Scott Hannon
% Update: 14 Apr 2011, S.Hannon - bug fix for dust inot indices
% Update: 04 May 2011, S.Hannon - add bto1232 & btc1232 output vars; rename
%    "*1231" variables to "*1232"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Test channels (note: must be sorted by ID)
%          1      2       3      4      5       6        7      8        9
%idtest=[  272;   332;    421;   499;   631;    675;     694;   710;     732];
ftest =[819.375;856.875;912.5;961.25;1043.75;1071.25;1083.125;1093.125;1232.5];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find indices of idtest in head.ichan
%[ichan index] = wn2ch(head, ftest);
index = [699; 849; 1071; 1266; 1596; 1706; 1754; 1794; 2351];

% Find sea and non-sea indices
ncheck = length(icheck);
isea = find(prof.landfrac(icheck) < 0.02);
inot = setdiff(1:ncheck,isea);


% Declare output array
iflags = zeros(1,ncheck);


% Compute BT of test channels
r = prof.robs1(index,icheck);
ibad = find(r < 1E-5);
r(ibad) = 1E-5;
bto = rad2bt(head.vchan(index), r);
r = prof.rcalc(index,icheck);
ibad = find(r < 1E-5);
r(ibad) = 1E-5;
btc = rad2bt(head.vchan(index), r);
clear r ibad


% Test #1 bitvalue=1: window channel dBT
ix1232 = 9; % ~1232 wn
%
bto1232 = bto(ix1232,:);
btc1232 = btc(ix1232,:);
dbt1232 = bto1232 - btc1232;
ii = isea( find(dbt1232(isea) > 4 | dbt1232(isea) < -3) );
iflags(ii) = iflags(ii) + 1;
ii = inot( find(dbt1232(inot) > 7 | dbt1232(inot) < -7) );
iflags(ii) = iflags(ii) + 1;


% Test #2 bitvalue=2: cirrus
ix820 = 1; % ~820 wn
ix856 = 2; % ~856 wn
ix960 = 4; % ~960 wn
%
dbt960 =  bto(ix960,:) - btc(ix960,:);
dbt820x = bto(ix820,:) - btc(ix820,:) - dbt960;
dbt856x = bto(ix856,:) - btc(ix856,:) - dbt960;
ii = isea( find(dbt820x(isea) < -0.5 & dbt856x(isea) < 0.5*dbt820x(isea)) );
iflags(ii) = iflags(ii) + 2;
ii = inot( find(dbt820x(inot) < -1.0 & dbt856x(inot) < 0.5*dbt820x(inot)) );
iflags(ii) = iflags(ii) + 2;


% Test #3 bitvalue=4: dust/ash
ix912  = 3; %  ~912 wn
ix1043 = 5; % ~1043 wn
ix1071 = 6; % ~1071 wn
ix1083 = 7; % ~1083 wn
ix1093 = 8; % ~1093 wn
%
dbt912x  = bto( ix912,:) - btc( ix912,:) - dbt1232;
dbt960x  = bto( ix960,:) - btc( ix960,:) - dbt1232;
dbt1043x = bto(ix1043,:) - btc(ix1043,:) - dbt1232;
dbt1071x = bto(ix1071,:) - btc(ix1071,:) - dbt1232;
dbt1083x = bto(ix1083,:) - btc(ix1083,:) - dbt1232;
dbt1093x = bto(ix1093,:) - btc(ix1093,:) - dbt1232;
ii = isea( find(dbt1083x(isea) < -0.5 & dbt960x(isea)+0.1 < dbt912x(isea)) );
iflags(ii) = iflags(ii) + 4;
ii = inot( find(dbt1083x(inot) < -1.0 & dbt960x(inot)+0.1 < dbt912x(inot)) );
iflags(ii) = iflags(ii) + 4;

% Test #4 bitvalue=8: marine boundary layer cloud (mblc)
ix912 = 3;  % ~912 wn
%
dbt912x  = bto( ix912,:) - btc( ix912,:);
ii =  isea( find(dbt912x(isea) <  -7.0) );
iflags(ii) = iflags(ii) + 8;


%%% end of function %%%
