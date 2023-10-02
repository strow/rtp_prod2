function [iflags, bto, btc] = chirp_find_clear(head, prof, opt);

% Do clear tests for the specified FOV/profile indices and
% return test results as bit flags. 
%
% Input:
%    head - RTP header structure with fields ichan and vchan
%    prof - RTP profiles structure with fields rclr, robs1,
%    landfrac. can contain only the obs selected as
%    uniform. klayers/sarta needs to be run to have rclr field for
%    at least the test window channel
%    OPTIONAL:
%    opt  - struct of configuration options for window channel and thresholds
%%
% Output: 
%    iflags - [1 x nobs] bit flags for the following tests: 1 =
%             abs(BTobs-BTcal) in window channel > threshold 
%    bto - [1 x nobs] BTobs of window channel 
%    btc - [1 x nobs] BTcal of window wchan 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sFuncName = 'chirp_find_clear';


% Check input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (nargin < 2 | nargin > 3)
   error(sprintf('>>> %s: unexpected number of input arguments',sFuncName))
end

wn = 961;  % 961 cm^-1 default
ocean_threshold = 4; 
land_threshold = 7;
scanlines = 135; % default number of CrIS scanlines per granule
if nargin == 3 
    if isfield(opt, 'clear_test_channel')
        wn = opt.clear_test_channel;
    end
    if isfield(opt, 'clear_ocean_bt_threshold')
        ocean_threshold = opt.clear_ocean_bt_threshold;
    end
    if isfield(opt, 'clear_land_bt_threshold')
        threshold = opt.clear_land_bt_threshold;
    end
    if isfield(opt, 'scanlines')
        scanlines = opt.scanlines;
    end
end

ch = find(head.vchan > wn, 1);
fprintf(1, '>> Clear test using channel %d : %7.3f\n', ch, ...
        head.vchan(ch))

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

% Declare output array
iflags = zeros(1,length(prof.rtime));

% Compute BT of test channels in observed radiances
r = prof.robs1(ch,:);
ibad = find(r < 1E-5);
r(ibad) = 1E-5;
bto = real(rad2bt(head.vchan(ch), r));

% Compute BT of test channels in observation sarta clear calcs
r = prof.rclr(ch,:);
ibad = find(r < 1E-5);
r(ibad) = 1E-5;
btc = real(rad2bt(head.vchan(ch), r));
clear r ibad

% Find sea and non-sea indices
sea_ind = prof.landfrac < 0.02;
% $$$ isea = find(sea_ind);
% $$$ iland = find(~sea_ind);

dbt = bto - btc;
% $$$ ii = isea( find(abs(dbt(isea) > ocean_threshold)));
iot = abs(dbt) > ocean_threshold;
ii = find(sea_ind & iot);
iflags(ii) = iflags(ii) + 1;
% $$$ ii = iland( find(abs(dbt(iland) > land_threshold)));
ilt = abs(dbt) > land_threshold;
ii = find(~sea_ind & ilt);
iflags(ii) = iflags(ii) + 1;
% % end of function %%%
