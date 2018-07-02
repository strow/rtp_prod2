function [prof, pattr, aux] = read_airixcal(fn);

% function [prof, pattr, aux] = read_airixcal(fn);
%
% Input: fn is a AIRIXCAL netcdf/rtp3 file Output: rtp structures prof and
% pattr, aux structure with variables needed to form prof.calflag
%
% This routine only assigns a small subset of variables in the
% AIRIXCAL file that we want in RTP files.  Edit this file to add more
% variables.  You must be careful to assign the correct pattr to each
% udef, iudef.
%
% Created: S. Buczkowski June 27, 2018

% Is the file name appropriate for an AIRIXCAL file?
% Some file name logic here
% $$$ if length(strfind(fn,'L1B.Cal_Subset')) == 0
% $$$    disp('Warning!! Doesn''t appear to be an AIRIXCAL file')
% $$$ end

%------------------------------------------------------------------------------
% Assign variable names
%------------------------------------------------------------------------------
% Fixed rtp fields (airixcal_name rtp_name)
% Do radiances separately (no cell2mat needed)
airixcal = {...
    'time'           'rtime'; ...
    'lat'            'rlat'; ...
    'lon'            'rlon'; ...
    'satalt'         'zobs'; ...  
    'findex'         'findex'; ...
    'atrack'         'atrack'; ...
    'xtrack'         'xtrack'; ...
    'satzen'         'satzen'; ...
    'solzen'         'solzen' ; ...
    'landfrac'       'landfrac'; ...
    'salt'           'salti'; ...
    'scanang'        'scanang'};

% $$$ % airixcal udef variables, in order (relative to pattr's)!
% $$$ airixcal_udef = {...
% $$$     'BT_diff_SO2' 'lp2395clim' 'cxlpn'  'cx2395' 'avnsst' ...
% $$$     'sst1231r5'   'cx1231'     'cx2616' 'cxq2'   'sun_glint_distance' };
airixcal_udef = {};

% airixcal iudef variables, in order (relative to pattr's)!
airixcal_iudef = {'reason' 'siteid' 'ascflag'};

% open netcdf file
ncid = netcdf.open(fn, 'NC_NOWRITE');
% AIRIXCAL files contain two groups: /IRInst and /MWInst for AIRS
% and AMSU data. We are only concerned with /IRInst and will pull
% data from that group only
irinstID = netcdf.inqNcid(ncid, 'IRInst');

%------------------------------------------------------------------------------
% Read in data
%------------------------------------------------------------------------------
% Read all radiances
varid = netcdf.inqVarID(irinstID, 'robs');
prof.robs1 = netcdf.getVar(irinstID, varid);

% Read in calflag
varid = netcdf.inqVarID(irinstID, 'calflag');
prof.calflag = netcdf.getVar(irinstID, varid);

% Read in inst-dependent quality flag (0 implies good)
varid = netcdf.inqVarID(irinstID, 'qual');
qual = netcdf.getVar(irinstID, varid);

% Read fixed rtp fields
for i=1:length(airixcal)
    varid = netcdf.inqVarID(irinstID, airixcal{i,1});
    prof.(airixcal{i,2}) = netcdf.getVar(irinstID, varid)';
end
% Correct prof.rtime to TAI-UT1 from AIRS TAI93
% See http://newsroom.gsfc.nasa.gov/sdptoolkit/primer/time_notes.html#TAI
% TAI93 zero time is UTC 12 AM 1-1-1993.  To convert to TAI-UT1 we
% must add the seconds from that date to 12 AM 1-1-1958 *and* add in
% the 27 leap seconds from 1958 to 1993 (since EOS used a UTC time as
% the start date).  mtime = datetime(1958,1,1,0,0,prof.rtime);
seconds1958to1993 = 12784 * 86400 + 27;
prof.rtime = prof.rtime + seconds1958to1993;

% Read udefs (udefs handled below. this is a no-op at the moment)
for i=1:length(airixcal_udef)
    varid = netcdf.inqVarID(irinstID, airixcal_udef{i});
    prof.udef(i,:) = netcdf.getVar(irinstID, varid);;
end

% Read iudefs
for i=1:length(airixcal_iudef)
    varid = netcdf.inqVarID(irinstID, airixcal_iudef{i});
    prof.iudef(i,:) = netcdf.getVar(irinstID, varid);;
end

% Read in qcinfo
varid = netcdf.inqVarID(irinstID, 'qcinfo');
qcinfo = netcdf.getVar(irinstID, varid);

% Read in iqcinfo
varid = netcdf.inqVarID(irinstID, 'iqcinfo');
iqcinfo = netcdf.getVar(irinstID, varid);

% build udefs from qcinfo (airixcal does not have full airxbcal
% compliment) (trying to match airxbcal indexing, though)
prof.udef(1,:) = qcinfo(4,:);  % BT_diff_SO2
prof.udef(10,:) = qcinfo(1,:);  % sun_glint_distance

% get dust_flag from iqcinfo and stuff into iudef. requires
% shifting around iudef as built above
prof.iudef(4,:) = prof.iudef(3,:);  % move asc flag to iudef(4)
prof.iudef(3,:) = iqcinfo(3,:);  % and insert dust_flag

% $$$ % Read fields needed for Scott's RTP calflag
varid = netcdf.inqVarID(irinstID, 'nenmean');
aux.NeN            = netcdf.getVar(irinstID, varid);

varid = netcdf.inqVarID(irinstID, 'fchan');
aux.nominal_freq   = netcdf.getVar(irinstID, varid);

% close netcdf file
netcdf.close(ncid);

%------------------------------------------------------------------------------
% Create attribute strings
%------------------------------------------------------------------------------
%  The iudef attributes must be in the same order as given in the
%  airixcal_iudef and airixcal_udef cell arrays.  You must initialize
%  the headers (here "profiles"), done in next command.
pattr = set_attr('profiles','robs1',fn);
pattr = set_attr(pattr,'rtime','TAI:1958');
% iudef attributes
pattr = set_attr(pattr, 'iudef(1,:)','Reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}');
pattr = set_attr(pattr, 'iudef(2,:)','Fixed site number {sitenum}');
pattr = set_attr(pattr, 'iudef(3,:)','Dust flag [1=true,0=false,-1=land,-2=cloud,-3=bad data] {dustflag}');
pattr = set_attr(pattr, 'iudef(4,:)','Node [Ascend/Descend/Npole/Spole/Zunknown] {scan_node_type}');

% udef attributes
pattr = set_attr(pattr, 'udef(1,:)','SO2 indicator BT(1361) - BT(1433) {BT_diff_SO2}');
pattr = set_attr(pattr, 'udef(10,:)','Sun glint distance');


