function [eq_x_tai, f, gdata, attr] = v6_readl2cc(fn, iQA);

% function [eq_x_tai, f, gdata] = readl2cc(fn, iQA);
%
% Reads an AIRS level 2 cloud-clear radiance granule file and returns
% an RTP-like structure of CC'ed observation data.  
% 
% Returns all 2378 channels but only those FOVs with a passing 
% retrieval quality flag defined by the "number of "bad" channels less 
% than 500 per FoV". Bad channels are ones with "radiances_QC==2".
%
% To bypass the test, you provide the iQA array indicating which 
% Fovs to be used. Use iQA = [1:1350] to get all FoVs.
%
% Input:
%    fn = (string) Name of an AIRS L2 granule file, something like
%            'AIRS.2003.10.18.023.L2.CC.v4.0.0.0.Focus.T04285042114.hdf'
%    iQA = optional [1 x nQA] passing RetQAFlag values. Default=0.
%
% Output:
%    eq_x_tai = (1 x 1) equator crossing time (TAI 1993)
%    f  = (nchan x 1) channel frequencies
%    gdata = (structure) RTP "prof" like structure with RetQAFlag
%       value returned in udef1
%
% Note: if the granule contains no good data, the output variables
% are returned empty.
%
% Breno Imbiriba - 2013.05.02 - based on Scott's readers

% Created: 08 Sep 2004, Scott Hannon - based on readl1b_all.m
% Update: 18 Oct 2004 S.Hannon - add calflag
% Update: 14 Dec 2004 S.Hannon - add iQA and input checks; add udef1
% Update: 10 May 2004 S.Hannon - add Qual_CC_Rad check (new for v4)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Granule dimensions
nchan=2378;
nxtrack=30;
natrack=45;
nobs=nxtrack*natrack;

% Check fn
d = dir(fn);
if (length(d) ~= 1)
   disp(['Error, bad fn: ' fn])
   return
end

% Check iQA
if (nargin == 2)
   d = size(iQA);
   if (length(d) ~= 2 | min(d) ~= 1)
      disp('Error, bad iQA')
      return
   end
else
   % Set default iQA
   iQA = [];
end
nQA = length(iQA);


% Open granule file
file_name=fn;
file_id  =hdfsw('open',file_name,'read');
swath_id =hdfsw('attach',file_id,'L2_Standard_cloud-cleared_radiance_product');

% Read "radiances_QC" flag 
[junk,s]=hdfsw('readfield',swath_id,'radiances_QC',[],[],[]);
if s == -1
   disp('Unable to check radiances_QC (does not exist)')
   junk = zeros(nobs, 2738);
end
radiances_QC = reshape( double(junk), [2378, nobs]);


% Lets make a fake QA flag
% radiances_QC = {0,1,2}, where '2' is "Don't use", aka BAD.
% By looking at hist(sum(radiances_QC==2)) we see a clear cut off at about
% 500 channels, i.e. 500 channels being BAD.
% So, we will set the line for BAD FoV as being one with 
% sum(radiances_QC==2)>500

% Define a rough assessement of bad granules.
% less than 500 channels bad
%lQA = (sum(radiances_QC==2)<500);
%i0 = find(lQA);
%n0 = numel(i0);
%
%if(numel(iQA)>0)
%  disp('Bypassing radiances_QC test');
%  i0 = iQA;
%  n0 = numel(iQA);
%end

%% Find FOVs with RetQAFlag in iQA
%i0 = find( ismember(retqaflag,iQA) == 1 & qual_cc_rad == 0);
%%%% The following line of code was used before qual_cc_rad was added
%%i0 = find( ismember(retqaflag,iQA) == 1);
%%%% This following line of code was used before iQA was added
%%i0=find( retqaflag == 0);  % Indices of "good" FOVs
%%%%
%n0=length(i0);
%%
%retqaflag = retqaflag(i0);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i0 = 1:nobs;   % -- dont subset
%if (n0 > 0)   % -- dont subset!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read per scanline fields; expand to per FOV later
%
% satheight (1 x natrack)
[junk,s]=hdfsw('readfield',swath_id,'satheight',[],[],[]);
if s == -1; disp('Error reading satheight'); end;
satheight = double(junk');
%

% Declare temporary variables for expansion
tmp_atrack=zeros(1,nobs);
tmp_xtrack=zeros(1,nobs);
tmp_zobs=zeros(1,nobs);
%
junk=blanks(nchan*nobs);
tmp_calflag=reshape(junk, nchan,nobs);  % large char array!
clear junk

% $$$ % Loop over along-track and fill in temporary variables
% $$$ ix=1:nxtrack;
% $$$ for ia=1:natrack
% $$$    iobs=nxtrack*(ia-1) + ix;
% $$$    %
% $$$    % Fill in cross-track
% $$$    tmp_atrack(iobs)=ia;
% $$$    tmp_xtrack(iobs)=ix;
% $$$    tmp_zobs(iobs)=satheight(ia)*1000;  % convert km to meters
% $$$    for ii=1:nxtrack
% $$$       tmp_calflag(:,iobs(ii))=radiances_QC(:,ia);
% $$$    end
% $$$ end
% $$$ %
% $$$ clear ix ia iobs satheight raw_calflag


% Subset temporary variables for state and re-assign to gdata
gdata.atrack = tmp_atrack(i0);
gdata.xtrack = tmp_xtrack(i0);
gdata.zobs   = tmp_zobs(i0);
% $$$ gdata.calflag= int8( tmp_calflag(:,i0) );
gdata.calflag = int8(radiances_QC(:,i0));
%
clear tmp_atrack tmp_xtrack tmp_zobs tmp_calflag


% Read in the channel freqs
[junk,s]=hdfsw('readfield',swath_id,'nominal_freq',[],[],[]);
if s == -1; 
  disp('Error reading freq - loading f_default_l1b.mat');
  junk = load('f_default_l1b.mat');
  junk = junk.f;
end;
f = double(junk);


% Read in observed radiance, reshape, and subset for state.
% Note: this is a large array!
% observed radiance is stored as (nchan x nxtrack x natrack)
[junk,s]=hdfsw('readfield',swath_id,'radiances',[],[],[]);
if s == -1; disp('Error reading radiances');end;
% reshape but do not convert to double yet
junk2 = reshape(junk, nchan,nobs);
clear junk
% subset and convert to double
gdata.robs1=double( junk2(:,i0) );
clear junk2

% read radiances_err
[junk,s]=hdfsw('readfield',swath_id,'radiance_err',[],[],[]);
if s == -1; disp('Error reading radiances_err');end;
% reshape but do not convert to double yet
junk2 = reshape(junk, nchan,nobs);
clear junk
% subset and convert to double
gdata.udef = double( junk2(:,i0) );
clear junk2



% Read the per FOV data
%
[junk,s]=hdfsw('readfield',swath_id,'Time',[],[],[]);
if s == -1; disp('Error reading Latitude');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.rtime = junk2(i0);
seconds1958to1993 = 12784 * 86400 + 27;
gdata.rtime = gdata.rtime + seconds1958to1993;

%
%
[junk,s]=hdfsw('readattr',swath_id,'eq_x_tai');
if s == -1; disp('Error reading eq_x_time');end;
eq_x_tai = junk;
%
%
[junk,s]=hdfsw('readfield',swath_id,'Latitude',[],[],[]);
if s == -1; disp('Error reading Latitude');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.rlat = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'Longitude',[],[],[]);
if s == -1; disp('Error reading Longitude');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.rlon = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'scanang',[],[],[]);
if s == -1; disp('Error reading scanang');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.scanang = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'satzen',[],[],[]);
if s == -1; disp('Error reading satzen');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.satzen = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'satazi',[],[],[]);
if s == -1; disp('Error reading satazi');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.satazi = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'solzen',[],[],[]);
if s == -1; disp('Error reading solzen');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.solzen = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'solazi',[],[],[]);
if s == -1; disp('Error reading solazi');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.solazi = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'topog',[],[],[]);
if s == -1; disp('Error reading topog');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.salti =junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'landFrac',[],[],[]);
if s == -1; disp('Error reading landFrac');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.landfrac = junk2(i0);
%
% $$$ [junk,s]=hdfsw('readfield',swath_id,'dust_flag',[],[],[]);
% $$$ if s == -1; disp('Error reading dust_flag');end;
% $$$ junk2 = resha5Ape( double(junk), 1,nobs);
% $$$ gdata.udef(2,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'scan_node_type',[],[],[]);
if s == -1; disp('Error reading scan_node_type');end;
junk2 = reshape( ones(nxtrack,1)*double(junk)', 1,nobs);
gdata.iudef(1,:) = junk2(i0);

% Read Attributes
[junk,s]=hdfsw('readattr',swath_id,'granule_number');
if s == -1; disp('Error reading landFrac');end;
junk2 = junk.*ones([1,nobs],class(junk));
gdata.findex = junk2(i0);

clear junk junk2 i0


% Assign RetQAFlag to udef1
% gdata.udef1 = retqaflag;


% Close L2CC granule file
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error: L2CC');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error: L2CC');end;

% Assign attribute strings
attr={{'profiles' 'rtime' 'Seconds since 0z, 1 Jan 1993'}, ...
      {'profiles' 'iudef(1,:)'  'Node [Ascend/Descend/Npole/Spole/Zunknown]'}, ...
      {'profiles' 'udef(1,:,:)' 'radiance_err'} };


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%else
%   disp('No good FOVs in L2CC granule file:')
%   disp(fn)
%
%   meantime=[];
%   f=[];
%   gdata=[];
%
%end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% end of function %%%
