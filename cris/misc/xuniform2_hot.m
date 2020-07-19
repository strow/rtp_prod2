function [dbtun, mbt] = xuniform2_hot(head, prof, idtest_lw, idtest_sw);

% function [dbtun, mbt] = uniform(head, prof, idtest);
%
% Determine spatial uniformity of CrIS data.  For each ifov it
% determines the max difference in mean BT (over idtest) of the
% eight adjacent ifovs.
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

% Created: 03 Mar 2011, Scott Hannon
% Update: 14 Mar 2011, S.Hannon - bug fix for bot & top inddbt
% Update: 04 May 2011, S.Hannon - made mbt an output variable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Required fields
hreq = {'ichan', 'vchan'};
preq = {'robs1', 'rtime', 'ifov', 'findex', 'atrack', 'xtrack'};

% Adjacent CrIS scanlines around about 8 seconds apart; round up to 9
dtamax = 9;

% CrIS FOV layout with
% increasing atrack up and increasing xtrack right
%%%
% The IASI-as-CrIS proxy data seems to be
%    007 004 001  016 013 010       268 265 262
%    008 005 002  017 014 011  ...  269 266 263
%    009 006 003  018 015 012       270 267 264
%ibot = zeros(1,90);
%ibot(1:3:88) = 9:9:270;
%ibot(2:3:89) = 6:9:267;
%ibot(3:3:90) = 3:9:264;
%imid = ibot - 1;
%itop = ibot - 2;
%%%
% I think the real CrIS data is supposed to
%    003 002 001  012 011 010       264 263 262
%    006 005 004  015 014 013  ...  267 266 265
%    009 008 007  018 017 016       270 269 268
%ibot = zeros(1,90);
%ibot(1:3:88) = 9:9:270;
%ibot(2:3:89) = 8:9:269;
%ibot(3:3:90) = 7:9:268;
%imid = ibot - 3;
%itop = ibot - 6;
%%%
% I think the real CrIS data is actually
%    007 008 009  016 017 018       268 269 270
%    004 005 006  013 014 015  ...  265 266 267
%    001 002 003  010 011 012       262 263 264
ibot = zeros(1,90);
ibot(1:3:88) = 1:9:262;
ibot(2:3:89) = 2:9:263;
ibot(3:3:90) = 3:9:264;
imid = ibot + 3;
itop = ibot + 6;
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input
if (nargin ~= 3)
   error('unexpected number of input arguments')
end
d = size(idtest);
if (length(d) ~=2 | min(d) ~= 1)
   error('unexpected dimensions for argument idtest')
end
ntest = length(idtest);
for ii=1:length(hreq)
   if (~isfield(head,hreq{ii}))
      error(['head is missing required field ' hreq{ii}])
   end
end
for ii=1:length(preq)
   if (~isfield(prof,preq{ii}))
      error(['prof is missing required field ' preq{ii}])
   end
end


% Determine indices of idtest in head.ichan
[idtestx,indtest,junk] = intersect(head.ichan,idtest);
if (length(idtestx) ~= ntest)
   error('did not find all idtest in head.ichan')
end


% Determine unique scanlines (as findex*100 + atrack)
% and their mean rtime
f100a = round(100*prof.findex + prof.atrack); % exact integer
uf100a = unique(f100a);
nscan = length(uf100a);
tscan = zeros(1,nscan);
for ii=1:nscan
   jj = find(f100a == uf100a(ii));
   tscan(ii) = mean(prof.rtime(jj));
end
nobs = length(prof.findex);


% Compute BT of test channels
ftest = head.vchan(indtest);
r = prof.robs1(indtest,:);
ibad = find(r < 1E-6);
r(ibad)=1E-6;
mbt = mean(radtot(ftest,r)); % [1 x nobs]
clear r


% Compute dbtun
dbtun = -9999*ones(1,nobs);

ix = 2:89;
ixm1 = ix - 1;
ixp1 = ix + 1;
dbt = zeros(ntest,length(ix));

for ii=1:nscan

%disp(['doing scanline ' int2str(ii) ' of ' int2str(nscan)])

   indscan = find(f100a == uf100a(ii));
   if (length(indscan) ~= 270)
      error('unexpected length for indscan')
   end
   dtscan = tscan(ii) - tscan;
   iprev = find(dtscan > 0 & dtscan < dtamax);
   inext = find(dtscan < 0 & dtscan > -dtamax);

   % Do bottom row
   if (length(iprev) == 1)
      indprev = find(f100a == uf100a(iprev));
      if (length(indprev) ~= 270)
         error('unexpected length for indprev')
      end
      btp = mbt(indprev(itop));
      btc = mbt(indscan(ibot));
      btn = mbt(indscan(imid));
      dbt(1,:) = abs(btc(ix) - btp(ixm1));
      dbt(2,:) = abs(btc(ix) - btp(ix));
      dbt(3,:) = abs(btc(ix) - btp(ixp1));
      dbt(4,:) = abs(btc(ix) - btc(ixm1));
      dbt(5,:) = abs(btc(ix) - btc(ixp1));
      dbt(6,:) = abs(btc(ix) - btn(ixm1));
      dbt(7,:) = abs(btc(ix) - btn(ix));
      dbt(8,:) = abs(btc(ix) - btn(ixp1));
%wrong      inddbt = indscan(imid(ix));
      inddbt = indscan(ibot(ix));
      dbtun(inddbt) = max(dbt);
   end


   % Do middle row
   btp = mbt(indscan(ibot));
   btc = mbt(indscan(imid));
   btn = mbt(indscan(itop));
   dbt(1,:) = abs(btc(ix) - btp(ixm1));
   dbt(2,:) = abs(btc(ix) - btp(ix));
   dbt(3,:) = abs(btc(ix) - btp(ixp1));
   dbt(4,:) = abs(btc(ix) - btc(ixm1));
   dbt(5,:) = abs(btc(ix) - btc(ixp1));
   dbt(6,:) = abs(btc(ix) - btn(ixm1));
   dbt(7,:) = abs(btc(ix) - btn(ix));
   dbt(8,:) = abs(btc(ix) - btn(ixp1));
   inddbt = indscan(imid(ix));
   dbtun(inddbt) = max(dbt);


   % Do top row
   if (length(inext) == 1)
      indnext = find(f100a == uf100a(inext));
      if (length(indnext) ~= 270)
         error('unexpected length for indnext')
      end
      btp = mbt(indscan(imid));
      btc = mbt(indscan(itop));
      btn = mbt(indnext(ibot));
      dbt(1,:) = abs(btc(ix) - btp(ixm1));
      dbt(2,:) = abs(btc(ix) - btp(ix));
      dbt(3,:) = abs(btc(ix) - btp(ixp1));
      dbt(4,:) = abs(btc(ix) - btc(ixm1));
      dbt(5,:) = abs(btc(ix) - btc(ixp1));
      dbt(6,:) = abs(btc(ix) - btn(ixm1));
      dbt(7,:) = abs(btc(ix) - btn(ix));
      dbt(8,:) = abs(btc(ix) - btn(ixp1));
%wrong      inddbt = indscan(ibot(ix));
      inddbt = indscan(itop(ix));
      dbtun(inddbt) = max(dbt);
   end

end

%%% end of routine %%%
