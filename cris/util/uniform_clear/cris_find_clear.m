function [iflags, wbto, wbtc, wchan] = cris_find_clear(head, prof, iobs2check);
% AIRSFINDCLEAR flag clear AIRS FOVs
%
% Do clear tests for the specified FOV/profile indices and
% return test results as bit flags. 
%
% Input:
%    head - RTP header structure with fields ichan and vchan
%    prof - RTP profiles structure with fields rcalc, robs1, landfrac
%    OPTIONAL:
%    iobs2check - [1 x ncheck] obs indices to check (likely often all obs
%    i.e. 1:length(prof.rtime) and this is its default value)
%
% Output: 
%    iflags - [1 x ncheck] bit flags for the following tests: 1 =
%             abs(BTobs-BTcal) at 1232 wn > threshold 2 = cirrus detected 4 =
%             dust/ash detected 
%    wbto - [1 x ncheck] BTobs of 1232 or 961 wn window 
%    wbtc - [1 x ncheck] BTcal of 1232 or 961 wn window wchan -
%           wavenumber of bto/btc window chan
%    wchan - wavenumber of channel used in last two outputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sFuncName = 'airs_find_clear';

% Test channels (wn) (note: must be sorted by ID)
%          1       2       3       4        5        6     7       8        9
ftest =[ 819.312;856.736;912.656;961.060;1043.863;1071.018;1083.364;1092.928;1232.368];
ntest = length(ftest);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find indices of idtest in head.ichan
[indtest, deltas] = matchWN2Ind(ftest, head.vchan);

% Check input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (nargin < 2 | nargin > 3)
   error(sprintf('>>> %s: unexpected number of input arguments',sFuncName))
end

% REVISITME: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% needed until renaming rcalc -> rclr is completed
% (safe to leave in after but, will be unnecessary)
% Mostly this is just needed to allow testing with existing allfov rtp data
% and, in normal use of straight granule reads, this would be handled by the 
% calling function after running sarta.
if (isfield(prof, 'sarta_rclearcalc') & isfield(prof, 'rcalc'))
    prof.rclr = prof.sarta_rclearcalc;
    prof.rcld = prof.rcalc;
    prof = rmfield(prof, 'sarta_rclearcalc');
    prof = rmfield(prof, 'rcalc');
elseif (isfield(prof, 'rcalc') & ~isfield(prof, 'sarta_rclearcalc'))
    prof.rclr = prof.rcalc;
    prof = rmfield(prof, 'rcalc');
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Required fields %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
hreq = {'ichan', 'vchan'}; 
preq = {'robs1', 'rclr', 'rtime'}; 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
for ii=1:length(hreq) 
    if (~isfield(head,hreq{ii})) 
       error(sprintf('>>> %s: head is missing required field %s', sFuncName, hreq{ii})) 
    end 
end 

for ii=1:length(preq) 
    if (~isfield(prof,preq{ii})) 
       error(sprintf('>>> %s: prof is missing required field %s', sFuncName, preq{ii}))
    end 
end 

% Set default value for iobs2check as all available obs
if (nargin == 2)
   nobs = length(prof.rtime);
   iobs2check = [1:nobs];
end

% Find sea and non-sea indices
ncheck = length(iobs2check);
isea = find(prof.landfrac(iobs2check) < 0.02);
inot = setdiff(iobs2check, isea);

% Declare output array
iflags = zeros(1,ncheck);

% Compute BT of test channels in observed radiances
r = prof.robs1(indtest,iobs2check);
ibad = find(r < 1E-5);
r(ibad) = 1E-5;
bto = real(rad2bt(head.vchan(indtest), r));

% Compute BT of test channels in observation sarta clear calcs
r = prof.rclr(indtest, iobs2check);
ibad = find(r < 1E-5);
r(ibad) = 1E-5;
btc = real(rad2bt(head.vchan(indtest), r));
clear r ibad

% Test #1 bitvalue=1: window channel dBT 
% REVISITME: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% which is preferred? 1232 or 961? Should this be externally
% controllable?
ix = 9; % ~1232 wn
% $$$ ix = 4;  % ~961 wn
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wchan = ftest(ix);
wbto = bto(ix,:);
wbtc = btc(ix,:);
wdbt = wbto - wbtc;
ii = isea( find(wdbt(isea) > 4 | wdbt(isea) < -3) );
iflags(ii) = iflags(ii) + 1;
ii = inot( find(wdbt(inot) > 7 | wdbt(inot) < -7) );
iflags(ii) = iflags(ii) + 1;
% % end of function %%%
