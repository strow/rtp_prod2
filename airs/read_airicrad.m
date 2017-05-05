function [eq_x_tai, f, gdata, attr] = read_airicrad(fn);

% function [eq_x_tai, f, gdata, attr] = xreadl1b_all(fn);
%
% Reads an AIRS level 1b granule file and returns an RTP-like structure of
% observation data.  Returns all 2378 channels and 90x135 FOVs.
%
% Input:
%    fn = (string) Name of an AIRS l1b granule file, something like
%          'AIRS.2000.12.15.084.L1B.AIRS_Rad.v2.2.0.64.A000'
%
% Output:
%    eq_x_tai = (1x 1) 1993 TAI time of southward equator crossing
%    f  = (nchan x 1) channel frequencies
%    gdata = (structure) RTP "prof" like structure
%    attr = (cell of strings) attribute strings
%
% Note: if the granule contains no good data, the output variables
% are returned empty.
%

% Created: 15 January 2003, Scott Hannon - based on readl1b_center.m
% Update: 11 March 2003, Scott Hannon - add check of field "state" so
%    routine only returns FOVs with no known problems.  Also correct
%    mis-assignment of calflag (previously was all wrong).
% Update: 26 March 2003, Scott Hannon - also check latitude ("state" is
%    not entirely reliable).
% Update: 02 Nov 2005, S.Hannon - add default f in case L1B entry is bad
% Update: 14 Jan 2010, S.Hannon - read granule_number and eq_x_tai; change
%    output meantime to eq_x_tai, add findex to gdata
% Update: 13 Oct 2010, S.Hannon - read rtime (previously estimated)
% Update: 16 Nov 2010, S.Hannon - read CalGranSummary & NeN; call
%    data_to_calnum_l1b; read nominal_freq
% Update: 15 Oct 2011, S.Hannon - add path for data_to_calnum_l1b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%addpath /asl/matlab2012/airs/utils  % data_to_calnum_l1b
% addpath /asl/matlab2012/airs/utils  % data_to_calnum_l1b
addpath(genpath('/home/sbuczko1/git/rtp_prod2/'));
%addpath /home/strow

% Granule dimensions
nchan=2645;
nxtrack=90;
natrack=135;
nobs=nxtrack*natrack;

% Default f
load /asl/matlab2012/airs/readers/f_default_l1c.mat
f_default = f;

% Open granule file
file_name = fn;
file_id   = hdfsw('open',file_name,'read');
swath_id  = hdfsw('attach',file_id,'L1C_AIRS_Science');


% Read "state" and find good FOVs
[junk,s]=hdfsw('readfield',swath_id,'state',[],[],[]);
if s == -1; disp('Error reading state');end;
state = reshape( double(junk), 1,nobs);
i0=find( state == 0);  % Indices of "good" FOVs
% $$$ i0=find( state == 1);  % Indices of "good" FOVs (v6 'Special' processing)
n0=length(i0);
%

% Read latitude
[junk,s]=hdfsw('readfield',swath_id,'Latitude',[],[],[]);
if s == -1; disp('Error reading latitude');end;
rlat = reshape( double(junk), 1,nobs);
ii=find( rlat > -90.01);  % Indices of "good" FOVs
i0=intersect(i0,ii);
n0=length(i0);

% $$$ % Read CalChanSummary
% $$$ [junk,s]=hdfsw('readfield',swath_id,'CalChanSummary',[],[],[]);
% $$$ if s == -1; disp('Error reading CalChanSummary');end;
% $$$ calchansummary = reshape( double(junk), nchan,1);

% Read NeN
% $$$ [junk,s]=hdfsw('readfield',swath_id,'NeN',[],[],[]);
% $$$ if s == -1; disp('Error reading NeN');end;
% $$$ nen = reshape( double(junk), nchan,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (n0 > 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read the date/time fields
[junk,s]=hdfsw('readattr',swath_id,'start_Time');
start_Time = double(junk(1));
%
[junk,s]=hdfsw('readattr',swath_id,'end_Time');
end_Time = double(junk(1));
%
[junk,s]=hdfsw('readattr',swath_id,'granule_number');
granule_number = double(junk(1));
%
[junk,s]=hdfsw('readattr',swath_id,'eq_x_tai');
eq_x_tai = double(junk(1));


% Compute granule mean TAI
meantai = 0.5*(start_Time + end_Time);
clear start_Time end_Time


% Read per scanline fields; expand to per FOV later
%
% calflag (nchan x natrack); read but do not convert to double yet
% $$$ [raw_calflag,s]=hdfsw('readfield',swath_id,'CalFlag',[],[],[]);
% $$$ if s == -1; disp('Error reading CalFlag'); end;
%
% satheight (1 x natrack)
[junk,s]=hdfsw('readfield',swath_id,'satheight',[],[],[]);
if s == -1; disp('Error reading satheight'); end;
satheight = double(junk'); %'


% Read in the channel freqs
% $$$ [junk,s]=hdfsw('readfield',swath_id,'spectral_freq',[],[],[]);
% $$$ if s == -1; disp('Error reading spectral_freq');end;
% $$$ f = double(junk);
% $$$ if (max(f) < -998)
% $$$    disp('WARNING! L1B file contains bad spectral_freq; using default')
% $$$    f = f_default;
% $$$ end
%
[junk,s]=hdfsw('readfield',swath_id,'nominal_freq',[],[],[]);
if s == -1; disp('Error reading nominal_freq');end;
nominal_freq = double(junk);
if (max(f) < -998)
   disp('WARNING! L1B file contains bad nominal_freq; using default')
   nominal_freq = f_default;
end


% Compute calnum
%disp('computing calnum')
% $$$ [calnum, cstr] = data_to_calnum_l1b(meantai, nominal_freq, nen, ...
% $$$    calchansummary, raw_calflag);
% $$$ %
% $$$ clear raw_calflag calchansummary nen nominal_freq meantai


% Declare temporary variables for expansion
tmp_atrack = zeros(1,nobs);
tmp_xtrack = zeros(1,nobs);
tmp_zobs   = zeros(1,nobs);
% $$$ tmp_calflag = zeros(nchan,nobs);


% Loop over along-track and fill in temporary variables
ix=1:nxtrack;
for ia=1:natrack
   iobs=nxtrack*(ia-1) + ix;
   %
   % Fill in cross-track
   tmp_atrack(iobs)=ia;
   tmp_xtrack(iobs)=ix;
   tmp_zobs(iobs)=satheight(ia)*1000;  % convert km to meters
%%% faster?
% $$$    tmp_calflag(:,iobs) = repmat(calnum(:,ia),1,nxtrack);
%%% slower?
%   for ii=1:nxtrack
%      tmp_calflag(:,iobs(ii))=calnum(:,ia);
%   end
%%%
end
%
clear ix ia iobs satheight


% Subset temporary variables for state and re-assign to gdata
gdata.findex = granule_number*ones(1,n0);
gdata.atrack = tmp_atrack(i0);
gdata.xtrack = tmp_xtrack(i0);
gdata.zobs   = tmp_zobs(i0);
% $$$ gdata.calflag= tmp_calflag(:,i0);
%
clear tmp_atrack tmp_xtrack tmp_zobs


% Read in observed radiance, reshape, and subset for state.
% Note: this is a very large array!
% observed radiance is stored as (nchan x nxtrack x natrack)
[junk,s]=hdfsw('readfield',swath_id,'radiances',[],[],[]);
if s == -1; disp('Error reading radiances');end;
% reshape but do not convert to double yet
junk2 = reshape(junk, nchan,nobs);
clear junk
% subset and convert to double
gdata.robs1=double( junk2(:,i0) );
clear junk2


% Read the per FOV data
gdata.rlat = rlat(i0);
clear rlat
%
[junk,s]=hdfsw('readfield',swath_id,'Longitude',[],[],[]);
if s == -1; disp('Error reading longitude');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.rlon = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'Time',[],[],[]);
if s == -1; disp('Error reading rtime');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.rtime = junk2(i0);
gdata.rtime = gdata.rtime  + 12784 * 86400 + 27;
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
[junk,s]=hdfsw('readfield',swath_id,'dust_flag',[],[],[]);
if s == -1; disp('Error reading dust_flag');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.iudef(1,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'dust_score',[],[],[]);
if s == -1; disp('Error reading dust_score');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.iudef(2,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'L1cProc',[],[],[]);
if s == -1; disp('Error reading L1cProc');end;
junk2 = reshape( double(junk), nobs,nchan);
gdata.iudef(3,:,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'L1cSynthReason',[],[],[]);
if s == -1; disp('Error reading L1cSynthReason');end;
junk2 = reshape( double(junk), nobs,nchan);
gdata.iudef(4,:,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'SceneInhomogeneous',[],[],[]);
if s == -1; disp('Error reading SceneInhomogeneous');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.iudef(5,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'AB_Weight',[],[],[]);
if s == -1; disp('Error reading AB_weight');end;
junk2 = reshape( double(junk), nobs,nchan);
gdata.iudef(6,:,:) = junk2(i0);
%

%
[junk,s]=hdfsw('readfield',swath_id,'scan_node_type',[],[],[]);
if s == -1; disp('Error reading scan_node_type');end;
junk2 = reshape( ones(90,1)*double(junk)', 1,nobs);
gdata.udef(1,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'sun_glint_distance',[],[],[]);
if s == -1; disp('Error reading sun_glint_distance');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.udef(2,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'spectral_clear_indicator',[],[],[]);
if s == -1; disp('Error reading Spectral_clear_indicator');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.udef(3,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'BT_diff_SO2',[],[],[]);
if s == -1; disp('Error reading BT_diff_SO2');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.udef(4,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'NeN',[],[],[]);
if s == -1; disp('Error reading NeN');end;
junk2 = reshape( double(junk), nobs,nchan);
gdata.udef(5,:,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'Inhomo850',[],[],[]);
if s == -1; disp('Error reading Inhomo850');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.udef(6,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'Rdiff_swindow',[],[],[]);
if s == -1; disp('Error reading Rdiff_swindow');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.udef(7,:) = junk2(i0);
%
[junk,s]=hdfsw('readfield',swath_id,'Rdiff_lwindow',[],[],[]);
if s == -1; disp('Error reading Rdiff_lwindow');end;
junk2 = reshape( double(junk), 1,nobs);
gdata.udef(8,:) = junk2(i0);
%

clear junk junk2 i0


% Close L1B granule file
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error: L1b');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error: L1b');end;


% Determine number of known imperfect channels for each FOV
% $$$ gdata.robsqual = sum(gdata.calflag >= 64);

% Assign attribute strings
attr={{'profiles' 'iudef(1,:)' 'Dust flag:[1=true,0=false,-1=land,-2=cloud,-3=bad data] {dustflag}'},...
      {'profiles' 'iudef(2,:)' 'Dust_score'},...
      {'profiles' 'iudef(3,:)' 'L1cProc'},...
      {'profiles' 'iudef(4,:)' 'L1cSynthReason'},...
      {'profiles' 'iudef(5,:)' 'SceneInhomogeneous'},...
      {'profiles' 'iudef(6,:)' 'AB_weight'},...
      {'profiles' 'udef(1,:)' 'scan_node_type'},...
      {'profiles' 'udef(2,:)' 'sun_glint_distance'},...
      {'profiles' 'udef(3,:)' 'spectral_clear_indicator'},...
      {'profiles' 'udef(4,:)' 'BT_diff_SO2'},...
      {'profiles' 'udef(5,:)' 'NeN'},...
      {'profiles' 'udef(6,:)' 'Inhomo850'},...
      {'profiles' 'udef(7,:)' 'Rdiff_swindow'},...
      {'profiles' 'udef(8,:)' 'Rdiff_lwindow'}};


% $$$       {'profiles' 'Node' '[Ascend/Descend/Npole/Spole/Zunknown] {scan_node_type}'},...
% $$$       {'profiles' 'sun_glint_distance' ''},...
% $$$       {'profiles' 'spectral_clear_indicator' ''},...
% $$$       {'profiles' 'BT_diff_SO2' ''},...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
   disp('No good FOVs in L1C granule file:')
   disp(fn)

   meantime=[];
   f=[];
   gdata=[];
   attr = [];

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% end of function %%%
