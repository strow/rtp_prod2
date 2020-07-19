function [iclear, dbtun] = airs_uniform_clear(head, hattr, prof, pattr)
% AIRS_UNIFORM_CLEAR select clear obs
% 
% Run the AIRS airs_uniform.m and airs_find_clear.m codes for a set of
% input observations. The input RTP must contain sarta clear calcs as
% p.rclr. Lack of a required field results in failure and exit from the
% routine
%
% test channel arrays are built in airs_find_clear and airs_uniform
%
% Input:
%   head, hattr, prof, pattr  - std RTP structures
%
% Output:
%    pout -   prof, but with added field prof.iudef having the settings of 0,1,2,4,8
%         = where 1,2,4,8 are uniform clear, site, dcc, random (0 otherwise)
%
% Created: April 2018, Steven Buczkowski - based on CrIS code from Scott Hannon and Sergio Machado
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sFuncName = 'airs_uniform_clear';

% $$$ addpath /asl/matlib/rtptools       % subset_rtp

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
preq = {'robs1', 'rclr'};
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

% Run xuniform
disp('running airs_find_uniform')
[dbtun, mbt] = airs_find_uniform(head, prof);
nobs = length(dbtun);
ibad1 = find(mbt < 150);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Run xfind_clear
disp('running airs_find_clear')
[iflagsc, bto1232, btc1232] = airs_find_clear(head, prof, 1:nobs);

iclear_sea    = find(iflagsc == 1 & abs(dbtun) < 0.5 & prof.landfrac <= 0.01);
iclear_notsea = find(iflagsc == 1 & abs(dbtun) < 1.0 & prof.landfrac >  0.01);
iclear = union(iclear_sea, iclear_notsea);


%%% end of program %%%
