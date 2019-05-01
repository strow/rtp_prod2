function [eq_x_tai, f, gdata, attr, opt] = read_airicrad(fn);
%
% Reads an AIRS level 1c granule file and returns an RTP-like structure of
% observation data.  Returns all 2645 channels and 90x135 FOVs.
%
% Input:
%    fn = (string) Name of an AIRS l1b granule file, something like
%          'AIRS.2016.12.10.229.L1C.AIRS_Rad.v6.1.2.0.G16346151726.hdf'
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
% L1C data is cleaned. Calnum based channel assessment as is done
% in L1B is unnecessary here as it is done in the raw data. Data
% that might have been rejected in L1B is filled with interpolated
% values. Channels which have been filled (and the reasons for that
% filling) can be tracked through L1CSynthReason (gdata.l1csreason)).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% establish local directory structure
currentFilePath = mfilename('fullpath');
[cfpath, cfname, cfext] = fileparts(currentFilePath);
fprintf(2, '>> Using file: %s\n', currentFilePath);

% Granule dimensions
nchan=2645;
nxtrack=90;
natrack=135;
nobs=nxtrack*natrack;

% Default f
% $$$ load /asl/matlab2012/airs/readers/f_default_l1c.mat
load(fullfile(cfpath, '../static/f_default_l1c.mat'))
f_default = f;

% Read "state" and find good FOVs
junk = hdfread(fn, 'state');
state = reshape( double(junk'), 1,nobs);
i0=find( state == 0);  % Indices of "good" FOVs
n0=length(i0);
%

% Read latitude
junk = hdfread(fn, 'Latitude');
rlat = reshape( double(junk'), 1,nobs);
ii=find( rlat > -90.01);  % Indices of "good" FOVs
i0=intersect(i0,ii);
n0=length(i0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (n0 > 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read the date/time fields
junk = cell2mat(hdfread(fn, 'start_Time'));
start_Time = double(junk(1));
%
junk = cell2mat(hdfread(fn, 'end_Time'));
end_Time = double(junk(1));
%
junk = cell2mat(hdfread(fn, 'granule_number'));
granule_number = double(junk(1));
%
junk = cell2mat(hdfread(fn, 'eq_x_tai'));
eq_x_tai = double(junk(1));


% Compute granule mean TAI
meantai = 0.5*(start_Time + end_Time);
clear start_Time end_Time

% Read per scanline fields; expand to per FOV later
%
% satheight (1 x natrack)
junk = cell2mat(hdfread(fn, 'satheight'));
satheight = double(junk'); %'

% Read in the channel freqs
junk = cell2mat(hdfread(fn, 'nominal_freq'));
nominal_freq = double(junk);
if (max(f) < -998)
   disp('WARNING! L1C file contains bad nominal_freq; using default')
   nominal_freq = f_default;
end

% Declare temporary variables for expansion
tmp_atrack = zeros(1,nobs);
tmp_xtrack = zeros(1,nobs);
tmp_zobs   = zeros(1,nobs);

% Loop over along-track and fill in temporary variables
ix=1:nxtrack;
for ia=1:natrack
   iobs=nxtrack*(ia-1) + ix;
   %
   % Fill in cross-track
   tmp_atrack(iobs)=ia;
   tmp_xtrack(iobs)=ix;
   tmp_zobs(iobs)=satheight(ia)*1000;  % convert km to meters
end
%
clear ix ia iobs satheight


% Subset temporary variables for state and re-assign to gdata
gdata.findex = granule_number*ones(1,n0);
gdata.atrack = tmp_atrack(i0);
gdata.xtrack = tmp_xtrack(i0);
gdata.zobs   = tmp_zobs(i0);
%
clear tmp_atrack tmp_xtrack tmp_zobs

% *** native reads with hdfread are atrack x xtrack (135 x 90) ***
% *** must transpose before reshaping to 1-D array             ***

% Read in observed radiance, reshape, and subset for state.
% Note: this is a very large array!
% observed radiance is stored as (nxtrack x natrack x nchan)
junk = permute(hdfread(fn, 'radiances'), [3 2 1]);
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
junk = hdfread(fn, 'Longitude');
junk2 = reshape( double(junk'), 1,nobs);
gdata.rlon = junk2(i0);
%
junk = hdfread(fn, 'Time');
junk2 = reshape( double(junk'), 1,nobs);
gdata.rtime = airs2tai(junk2(i0));
%
junk = hdfread(fn, 'scanang');
junk2 = reshape( double(junk'), 1,nobs);
gdata.scanang = junk2(i0);
%
junk = hdfread(fn, 'satzen');
junk2 = reshape( double(junk'), 1,nobs);
gdata.satzen = junk2(i0);
%
junk = hdfread(fn, 'satazi');
junk2 = reshape( double(junk'), 1,nobs);
gdata.satazi = junk2(i0);
%
junk = hdfread(fn, 'solzen');
junk2 = reshape( double(junk'), 1,nobs);
gdata.solzen = junk2(i0);
%
junk = hdfread(fn, 'solazi');
junk2 = reshape( double(junk'), 1,nobs);
gdata.solazi = junk2(i0);
%
junk = hdfread(fn, 'topog');
junk2 = reshape( double(junk'), 1,nobs);
gdata.salti =junk2(i0);
%
junk = hdfread(fn, 'landFrac');
junk2 = reshape( double(junk'), 1,nobs);
gdata.landfrac = junk2(i0);
%
junk = permute(hdfread(fn, 'L1cProc'), [3 2 1]);
junk2 = reshape( double(junk), nchan, nobs);
gdata.l1cproc = junk2(:,i0);
%
junk = permute(hdfread(fn, 'L1cSynthReason'), [3 2 1]);
junk2 = reshape( double(junk), nchan, nobs);
gdata.l1csreason = junk2(:,i0);
%
junk = cell2mat(hdfread(fn,'sat_lat'));
junk2 = reshape(repmat(junk,90,1), 1, nobs);
gdata.satlat = junk2(i0);
%
junk = cell2mat(hdfread(fn,'sat_lon'));
junk2 = reshape(repmat(junk,90,1), 1, nobs);
opt.satlon = junk2(i0);
%
% iudefs (maximum of 10?)
junk = hdfread(fn, 'dust_flag');
junk2 = reshape( double(junk'), 1,nobs);
gdata.iudef(1,:) = junk2(i0);
%
junk = hdfread(fn, 'dust_score');
junk2 = reshape( double(junk'), 1,nobs);
gdata.iudef(2,:) = junk2(i0);
%
junk = hdfread(fn, 'SceneInhomogeneous');
junk2 = reshape( double(junk'), 1,nobs);
gdata.iudef(3,:) = junk2(i0);
%
junk = cell2mat(hdfread(fn, 'scan_node_type'));
junk2 = reshape( (ones(90,1)*double(junk))', 1,nobs);
gdata.iudef(4,:) = junk2(i0);
%
junk = permute(hdfread(fn, 'AB_Weight'), [3 2 1]);
junk2 = reshape( double(junk), nchan, nobs);
opt.ABweight = junk2(:,i0);
%

% udefs (maximum of 20?)
%
junk = hdfread(fn, 'sun_glint_distance');
junk2 = reshape( double(junk'), 1,nobs);
gdata.udef(1,:) = junk2(i0);
%
junk = hdfread(fn, 'spectral_clear_indicator');
junk2 = reshape( double(junk'), 1,nobs);
gdata.udef(2,:) = junk2(i0);
%
junk = hdfread(fn, 'BT_diff_SO2');
junk2 = reshape( double(junk'), 1,nobs);
gdata.udef(3,:) = junk2(i0);
%
junk = permute(hdfread(fn, 'NeN'), [3 2 1]);
junk2 = reshape( double(junk), nchan, nobs);
opt.NeN = junk2(:,i0);
%
junk = hdfread(fn, 'Inhomo850');
junk2 = reshape( double(junk'), 1,nobs);
gdata.udef(4,:) = junk2(i0);
%
junk = hdfread(fn, 'Rdiff_swindow');
junk2 = reshape( double(junk'), 1,nobs);
gdata.udef(5,:) = junk2(i0);
%
junk = hdfread(fn, 'Rdiff_lwindow');
junk2 = reshape( double(junk'), 1,nobs);
gdata.udef(6,:) = junk2(i0);
%

clear junk junk2 i0

% Assign attribute strings
attr={{'profiles' 'iudef(1,:)' 'Dust flag:[1=true,0=false,-1=land,-2=cloud,-3=bad data]'},...
      {'profiles' 'iudef(2,:)' 'Dust_score:[>380 (probable), N/A if Dust Flag < 0]'},...
      {'profiles' 'iudef(3,:)' 'SceneInhomogeneous:[128=inhomogeneous,64=homogeneous]'},...
      {'profiles' 'iudef(4,:)' 'scan_node_type [0=Ascending, 1=Descending]'},...
      {'profiles' 'udef(1,:)' 'sun_glint_distance:[km to sunglint,-9999=unknown,30000=no glint]'},...
      {'profiles' 'udef(2,:)' 'spectral_clear_indicator:[2=ocean clr,1=ocean n/clr,0=inc. data,-1=land n/clr,-2=land clr]'},...
      {'profiles' 'udef(3,:)' 'BT_diff_SO2:[<-6, likely volcanic input]'},...
      {'profiles' 'udef(4,:)' 'Inhomo850:[abs()>0.84 likely inhomogeneous'},...
      {'profiles' 'udef(5,:)' 'Rdiff_swindow'},...
      {'profiles' 'udef(6,:)' 'Rdiff_lwindow'}};

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
