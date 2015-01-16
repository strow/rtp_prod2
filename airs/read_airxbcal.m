function [prof, pattr, aux] = read_airxbcal(fn);

% function [prof, pattr, aux] = read_airxbcal(fn);
%
% Input: fn is a AIRXBCAL .hdf file Output: rtp structures prof and
% pattr, aux structure with variables needed to form prof.calflag
%
% This routine only assigns a small subset of variables in the
% AIRXBCAL file that we want in RTP files.  Edit this file to add more
% variables.  You must be careful to assign the correct pattr to each
% udef, iudef.
%
% Created: L. Strow, Jan. 8, 2015

% Is the file name appropriate for an AIRXBCAL file?
% Some file name logic here
if length(strfind(fn,'L1B.Cal_Subset')) == 0
   disp('Warning!! Doesn''t appear to be an AIRXBCAL file')
end

addpath /asl/matlib/rtptools

%------------------------------------------------------------------------------
% Assign variable names
%------------------------------------------------------------------------------
% Fixed rtp fields (airxbcal_name rtp_name)
% Do radiances separately (no cell2mat needed)
airxbcal = {...
    'Time'           'rtime'; ...
    'Latitude'       'rlat'; ...
    'Longitude'      'rlon'; ...
    'satheight'      'zobs'; ...
    'granule_number' 'findex'; ...
    'scan'           'atrack'; ...
    'footprint'      'xtrack'; ...
    'satzen'         'satzen'; ...
    'solzen'         'solzen' ; ...
    'LandFrac'       'landfrac'; ...
    'topog'          'salti'};

% airxbcal udef variables, in order (relative to pattr's)!
airxbcal_udef = {...
    'BT_diff_SO2' 'lp2395clim' 'cxlpn'  'cx2395' 'avnsst' ...
    'sst1231r5'   'cx1231'     'cx2616' 'cxq2'   'sun_glint_distance' };

% airxbcal iudef variables, in order (relative to pattr's)!
airxbcal_iudef = {'reason' 'site' 'dust_flag' 'scan_node_type'};

%------------------------------------------------------------------------------
% Read in data
%------------------------------------------------------------------------------
% Read all radiances
prof.robs1 = hdfread(fn,'radiances')';

% Read fixed rtp fields
for i=1:length(airxbcal)
  prof.(airxbcal{i,2}) = cell2mat(hdfread(fn,airxbcal{i,1}));
end

% Read udefs
for i=1:length(airxbcal_udef)
  prof.udef(i,:) = cell2mat(hdfread(fn,airxbcal_udef{i}));
end

% Read iudefs
for i=1:length(airxbcal_iudef)
  prof.iudef(i,:) = cell2mat(hdfread(fn,airxbcal_iudef{i}));
end

% Read visible sensor fields (needs transpose?)
prof.udef([11 12 13],:) = hdfread(fn,'VisStdDev')';
prof.udef([14 15 16],:) = hdfread(fn,'VisMean')';

%------------------------------------------------------------------------------
% Create attribute strings
%------------------------------------------------------------------------------
%  The iudef attributes must be in the same order as given in the
%  airxbcal_iudef and airxbcal_udef cell arrays.  You must initialize
%  the headers (here "profiles"), done in next command.
pattr = set_attr('profiles','robs1',fn);
% iudef attributes
pattr = set_attr(pattr, 'iudef(1,:)','Reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}');
pattr = set_attr(pattr, 'iudef(2,:)','Fixed site number {sitenum}');
pattr = set_attr(pattr, 'iudef(3,:)','Dust flag [1=true,0=false,-1=land,-2=cloud,-3=bad data] {dustflag}');
pattr = set_attr(pattr, 'iudef(4,:)','Node [Ascend/Descend/Npole/Spole/Zunknown] {scan_node_type}');

% udef attributes
pattr = set_attr(pattr, 'udef(1,:)','SO2 indicator BT(1361) - BT(1433) {BT_diff_SO2}');
pattr = set_attr(pattr, 'udef(2,:)','Climatological pseudo lapse rate threshold {lp2395clim}');
pattr = set_attr(pattr, 'udef(3,:)','Spacial coherence of pseudo lapse rate {cxlpn}');
pattr = set_attr(pattr, 'udef(4,:)','Spacial coherence of 2395 wn {cx2395}');
pattr = set_attr(pattr, 'udef(5,:)','Aviation forecast sea surface temp {AVNSST}');
pattr = set_attr(pattr, 'udef(6,:)','Surface temp estimate {sst1231r5}');
pattr = set_attr(pattr, 'udef(7,:)','Spatial coherence of 1231 wn {cx1231}');
pattr = set_attr(pattr, 'udef(8,:)','Spatial coherence of 2616 wn {cx2616}');
pattr = set_attr(pattr, 'udef(9,:)','Spatial coherence of water vapor {cxq2}');
pattr = set_attr(pattr, 'udef(10,:)','Sun glint distance');

% Vis sensor attributes
pattr = set_attr(pattr, 'udef(11,:)','Visible channel 1 STD {VIS_1_stddev}');
pattr = set_attr(pattr, 'udef(12,:)','Visible channel 2 STD {VIS_2_stddev}');
pattr = set_attr(pattr, 'udef(13,:)','Visible channel 3 STD {VIS_3_stddev}');
pattr = set_attr(pattr, 'udef(14,:)','Visible channel 1 {VIS_1_mean}');
pattr = set_attr(pattr, 'udef(15,:)','Visible channel 2 {VIS_2_mean}');
pattr = set_attr(pattr, 'udef(16,:)','Visible channel 3 {VIS_3_mean}');

% Read fields needed for Scott's RTP calflag
aux.NeN            = hdfread(fn,'NeN')';
aux.CalChanSummary = hdfread(fn,'CalChanSummary')';
aux.nominal_freq   = cell2mat(hdfread(fn,'nominal_freq'))';

