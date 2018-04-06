function [dbtun, mbt] = airs_uniform(head, prof, idtest);
% AIRS_UNIFORM FOV spatial uniformity check
% *** build 3x3 FOR/FOV like structure by grouping AIRs scanlines
% *** in groups of 3 atracks
%
% Determine spatial uniformity of AIRS data.  For each ifov it
% determines the max difference in mean BT (over channels in idtest)
% of the eight adjacent ifovs.
%
% Input:
%    head    - [structure] RTP header with required fields: (ichan, vchan)
%    prof    - [structure] RTP profiles with required fields: (robs1,
%                 rtime, ifov, atrack, xtrack, findex)
%    idtest  - [1 x ntest] ID of test channels
%
% Output:
%    dbtun   - [1 x nobs] max delta BT {K}; -9999 if no data
%    mbt     - [1 x nobs] mean BTobs {K} used in dbtun tests

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sFuncName = 'airs_uniform';

% Check input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (nargin ~= 3)
   error(sprintf('>>> %s: unexpected number of input arguments',sFuncName))
end
d = size(idtest);
if (length(d) ~=2 | min(d) ~= 1)
   error(sprintf('>>> %s: unexpected dimensions for argument idtest',sFuncName))
end

% Required fields %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
hreq = {'ichan', 'vchan'}; 
preq = {'robs1', 'rtime', 'findex', 'atrack', 'xtrack'}; 
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

% Determine indices of idtest in head.ichan
[idtestx,indtest,~] = intersect(head.ichan,idtest);
ntest = length(idtest);
if (length(idtestx) ~= ntest)
   error('did not find all idtest in head.ichan')
end
clear idtestx
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AIRS observations come as a scanline of single FOVs which can addressed directly
% by values of prof.xtrack and prof.atrack. Gymnastics similar to CrIS will still be 
% required to match up FOVs for the actual uniformity tests
%    001 002 003  004 005 006       088 089 090
%    001 002 003  004 005 006  ...  088 089 090
%    001 002 003  004 005 006       088 089 090
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Compute BT of test channels
ftest = head.vchan(indtest);
r = prof.robs1(indtest,:);
ibad = find(r < 1E-6);
r(ibad)=1E-6;
mbt = mean(real(rad2bt(ftest,r))); % [1 x nobs]
clear r

% Determine unique scanlines (as findex*200 + atrack) and their mean
% rtime 
% *NOTE: the multiplier 200 needs to be as large, or larger,
% than the range of atrack values for the instrument. For AIRS, this range
% is 1:135. Original CrIS version which served as the base for this uses 100
% where CrIS granules have 4,60,90 atrack values typically. CrIS rtp data 
% does not carry findex values so this really only works reliably for a single
% granule while for AIRS, this code should be reliably general.

f100a = round(200*prof.findex + prof.atrack); % exact integer
uf100a = unique(f100a);
nscan = length(uf100a);
tscan = zeros(1,nscan);
for ii=1:nscan
   jj = find(f100a == uf100a(ii));
   tscan(ii) = mean(prof.rtime(jj));
end
nobs = length(prof.findex);

% Adjacent AIRS scanlines are around 2.667 seconds apart; round up to 3
dtamax = 3;

% Compute dbtun
dbtun = -9999*ones(1,nobs);

ix = 2:89;
ixm1 = ix - 1;
ixp1 = ix + 1;
dbt = zeros(ntest,length(ix));

FOVsPerScan = 90;  % 90 FOVs/AIRS scanline  (CrIS has 270)

% Loop over available scanlines. Since we ultimately need 3x3 matrices
% of obs for the uniformity test and AIRS scanlines are a single line
% of obs, we start on scanline two. Similarly, we lose the last line.

for ii=2:nscan-1

   indscan = find(f100a == uf100a(ii));
   if (length(indscan) ~= FOVsPerScan)
      error(sprintf('>>> %s: unexpected length for indscan', sFuncName))
   end
   dtscan = tscan(ii) - tscan;
   iprev = find(dtscan > 0 & dtscan < dtamax);
   inext = find(dtscan < 0 & dtscan > -dtamax);

   % Grab previous row
   if (length(iprev) == 1)
      indprev = find(f100a == uf100a(iprev));
      if (length(indprev) ~= FOVsPerScan)
	 error(sprintf('>>> %s: unexpected length for indprev', sFuncName))
      end
   end
   % Grab next row
   if (length(inext) == 1)
      indnext = find(f100a == uf100a(inext));
      if (length(indnext) ~= FOVsPerScan)
	 error(sprintf('>>> %s: unexpected length for indnext', sFuncName))
      end
   end
      btp = mbt(indnext);
      btc = mbt(indscan);
      btn = mbt(indprev);
      dbt(1,:) = abs(btc(ix) - btp(ixm1));
      dbt(2,:) = abs(btc(ix) - btp(ix));
      dbt(3,:) = abs(btc(ix) - btp(ixp1));
      dbt(4,:) = abs(btc(ix) - btc(ixm1));
      dbt(5,:) = abs(btc(ix) - btc(ixp1));
      dbt(6,:) = abs(btc(ix) - btn(ixm1));
      dbt(7,:) = abs(btc(ix) - btn(ix));
      dbt(8,:) = abs(btc(ix) - btn(ixp1));
      inddbt = indscan(ix);
      dbtun(inddbt) = max(dbt);
end

%%% end of routine %%%
