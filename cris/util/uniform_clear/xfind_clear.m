function [iflags, bto, btc] = xfind_clear(head, prof, icheck);

% function [iflags, bto1232, btc1232] = xfind_clear(head, prof, icheck);
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
%    bto1232 - [1 x ncheck] BTobs of 1232 wn
%    btc1232 - [1 x ncheck] BTcal of 1232 wn
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wn = 961;
itest = find(head.vchan > wn,1);

% Find sea and non-sea indices
ncheck = length(icheck);
isea = find(prof.landfrac(icheck) < 0.02);
inot = setdiff(1:ncheck,isea);


% Declare output array
iflags = zeros(1,ncheck);


% Compute BT of test channels
r = prof.robs1(itest,icheck);
ibad = find(r < 1E-5);
r(ibad) = 1E-5;
bto = rad2bt(head.vchan(itest), r);
r = prof.rclr(itest,icheck);
ibad = find(r < 1E-5);
r(ibad) = 1E-5;
btc = rad2bt(head.vchan(itest), r);
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


%%% end of function %%%
