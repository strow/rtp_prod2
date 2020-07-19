function [uflag, btall, btsub, nall, nsub, stdall, stdsub] = imager_uniformity(sfile);

% function [uflag, btall, btsub, nall, nsub, stdall, stdsub]=imager_uniform(...
%   IASI_Image, drnoise, dbtmaxall, dbtmaxsub, nminall, nminsub, stdmaxall, ...
%   stdmaxsub);
%
% For each of the "n" FOVs do a spatial uniformity test on the entire
% 64x64 imager data, and also do a uniformity tests on four 40x40 imager
% subsets.
%
% Input:
%    IASI_Image= [n x 4096] IASI Imager radiance data
%
% Presets:
%    drnoise   = [1 x 1] imager delta R noise (1.0)
%    dbtmaxall = [1 x 1] max delta BT for entire FOV uniformity test(8.0)
%    dbtmaxsub = [1 x 1] max delta BT for sub FOV uniformity test (3.0)
%    nminall   = [1 x 1] min # of imager pixels within dbtmaxall+noise (4075)
%    nminsub   = [1 x 1] min # of imager pixels within dbtmaxsub+noise (1588)
%    stdmaxall = [1 x 1] max std dev of entire imager pixels
%    stdmaxsub = [1 x 1] max std dev of subset imager pixels
%
% Output:
%    uflag  = [n x 4] uniform flag (0=not, 1=uniform)
%    btall  = [n x 1] mean BT of all imager pixels
%    btsub  = [n x 4] mean BT of subset imager pixels
%    nall   = [n x 1] number of imager pixels within dbtmaxall+noise of mean
%    nsub   = [n x 4] number of imager pixels within dbtmaxsub+noise of mean
%    stdall = [n x 1] std dev of entire IASI Imager
%    stdsub = [n x 4] std dev of subset IASI Imager
%
% Dependenices:
%  a. /asl/matlab2012/aslutil/ttorad.m, radtot.m
%  b. readl1c_epsflip_all.m
%
% Created: 5 April 2007, Scott Hannon - based on readl1c_uniform2x2.m
% Update: 10 April 2007, Scott Hannon - pass in IASI_Image rather than read it;
%    generic leading dimension "n" (not manditory n=660); always process
%    subsets.
% Update: 19 April 2007, S.Hannon - add missing stdmax checks
% Update: 03 May 2010, S.Hannon - fix reversed indices for ifovs 1 and 3
% Update: 28 Sep 2010, S.Hannon - bug fix for ifov 2 imager pixel indices
%    broken by 03 May 2010 bug fix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit this section as needed


% netcdf tools

% Channel freq of IASI imager channel for BT conversion
fimager = 890.0;

% Expected data dimensions
npixfov = 4;    % number of IASI "pixels" per FOV (ie 2x2 = 4)
nimager = 4096; % number of IASI Imager pixels (64 x 64)
% Note: an IASI "FOV" is composed of a 2x2 square of IASI "pixels".

% tiny default radiance to plug in when radiance is negative
rtiny = ttorad(fimager,150);

% imager_uniform arguments
  drnoise = 2;
  dbtmaxall = 7;
  dbtmaxsub = 2;
  nminall = 4055; % of 4096
  nminsub = 1587; % of 1600
  stdmaxall = 1.7;
  stdmaxsub = 0.5;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load the granule
data = readl1c_epsflip_all(sfile);

d = size(data.IASI_Image);
if (length(d) ~= 2 | d(2) ~= nimager)
   error('unexpected dimensions for IASI_Image data')
end
nax = d(1);

IASI_Image = data.IASI_Image;

% Declare empty output variables
uflag  = zeros(nax,npixfov);
nall   = zeros(nax,1);
nsub   = zeros(nax,npixfov);
stdall = zeros(nax,1);
stdsub = zeros(nax,npixfov);


% Replace bad imager data with rtiny
ibad = find(IASI_Image < rtiny);
if (length(ibad) > 0)
   IASI_Image(ibad) = rtiny;
end


% Indices for imager FOV subsets
% Note: IASI 2x2 centered at roughly [20,20], [20,44], [44,20], [44,44]
indsub = zeros(40*40,npixfov);
ind1to40 = 1:40;
for jj = 1:40
   ind=(jj-1)*40 + ind1to40;
   indsub(ind,4) = ind1to40 + 64*(jj-1);
%%% old
%   indsub(ind,3) = indsub(ind,4) + 24;
%   indsub(ind,1) = indsub(ind,4) + 64*24;
%%% corrected 03 May 2010
   indsub(ind,1) = indsub(ind,4) + 24;
   indsub(ind,3) = indsub(ind,4) + 64*24;
%%% old
%   indsub(ind,2) = indsub(ind,1) + 24;
%%% corrected 28 Sep 2010
    indsub(ind,2) = indsub(ind,3) + 24;
end


% Loop over the IASI imager FOVs
bhrall = dbtmaxall/2.0; % half range
bhrsub = dbtmaxsub/2.0; % half range
%
for ii = 1:nax
   % BT of all imager pixels
   bta = radtot(fimager,IASI_Image(ii,:));

   % Mean BT and std dev of BT of all imager pixels
   btall(ii) = mean(bta);
   stdall(ii) = std(bta);

   % Convert delta R noise to delta BT noise
   rmean = ttorad(fimager,btall(ii));
   junk = radtot(fimager,rmean+drnoise);
   bhnoise = (junk - btall(ii))/2; % half delta BT noise
   bqnoise = bhnoise/2; % quarter delta BT noise

   % Find imager pixels within "all" dbt range
   bhralln = bhrall + bhnoise;
   ipass = find( bta > (btall(ii) - bhralln) & bta < (btall(ii) + bhralln));
   nall(ii) = length(ipass);

%%%
%   % If "all" is OK, do subsets
%   if (nall(ii) >= nminall)
%%%

      % Loop over the subsets
      for jj=1:npixfov

         % BT of subset
         bts = bta( indsub(:,jj) );

         % Mean BT and std dev of BT of subset
         btsub(ii,jj) = mean(bts);
         stdsub(ii,jj) = std(bts);

         % Find imager pixels within "sub" dbt range
         bhrsubn = bhrsub + bhnoise;
         ipass = find( bts > (btsub(ii,jj) - bhrsubn) & ...
                       bts < (btsub(ii,jj) + bhrsubn) );
         nsub(ii,jj) = length(ipass);

         % If "sub" is OK, update uniformity flag
%         if (nsub(ii,jj) >= nminsub)
         % If "sub" and stds are OK, update uniformity flag
         if (stdall(ii) < stdmaxall+bqnoise & ...
             stdsub(ii,jj) < stdmaxsub+bqnoise & ...
             nsub(ii,jj) >= nminsub)
            uflag(ii,jj) = 1;
         end

      end % for npixfov

%%%
%   end % if nall
%%%

end % for nax

%%% end of function %%%
