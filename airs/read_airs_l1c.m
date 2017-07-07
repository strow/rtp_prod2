function [l1c] = read_airs_l1c(fn);

% Fixed rtp fields (airicrad_name rtp_name)
% Do radiances separately (no cell2mat needed)
airicrad = {...
    'Time'           'rtime'; ...
    'Latitude'       'rlat'; ...
    'Longitude'      'rlon'; ...
    'satheight'      'zobs'; ...
    'granule_number' 'findex'; ...
%    'scan'           'atrack'; ...
%    'footprint'      'xtrack'; ...
    'satzen'         'satzen'; ...
    'solzen'         'solzen' ; ...
    'landFrac'       'landfrac'; ...
    'topog'          'salti'};

% airicrad udef variables, in order (relative to pattr's)!
airicrad_udef = {...
    'BT_diff_SO2' 'sun_glint_distance' };
%'lp2395clim' 'cxlpn'  'cx2395' 'avnsst' 'sst1231r5'   'cx1231'     'cx2616' 'cxq2'   

% airicrad iudef variables, in order (relative to pattr's)!
airicrad_iudef = {'dust_flag' 'scan_node_type'};

%------------------------------------------------------------------------------
% Read in data
%------------------------------------------------------------------------------
% granule should have, nominally, ntrack=135, nfov=90, nchan=2645
% read in radiances
radiances = hdfread(fn,'radiances');
[ntrack, nfov, nchan] = size(radiances);
nobs = ntrack*nfov;
l1c.radiances = reshape(radiances, nobs, nchan)';
clear radiances

% Read fixed rtp fields
for i=1:length(airicrad)
    prof.(airicrad{i,2}) = reshape( cell2mat(hdfread(fn,airicrad{i,1})), 1, nobs);
end
clear temp;

Latitude = hdfread(fn,'Latitude');
[ntrack, nfov] = size(Latitude);
l1c.Latitude = reshape(Latitude, 1, nobs);
clear Latitude;


l1c.Longitude = reshape(hdfread(fn,'Longitude'), 1, nobs);
l1c.Time = reshape(hdfread(fn,'Time'), 1, nobs);
l1c.scanang = reshape(hdfread(fn,'scanang'), 1, nobs);
l1c.satzen = reshape(hdfread(fn,'satzen'), 1, nobs);
l1c.satazi = reshape(hdfread(fn,'satazi'), 1, nobs);
l1c.solzen = reshape(hdfread(fn,'solzen'), 1, nobs);
l1c.solazi = reshape(hdfread(fn,'solazi'), 1, nobs);
l1c.sun_glint_distance = reshape(hdfread(fn,'sun_glint_distance'), 1, nobs);
l1c.topog = reshape(hdfread(fn,'topog'), 1, nobs);
l1c.topog_err = reshape(hdfread(fn,'topog_err'), 1, nobs);
l1c.landFrac = reshape(hdfread(fn,'landFrac'), 1, nobs);
l1c.landFrac_err = reshape(hdfread(fn,'landFrac_err'), 1, nobs);
l1c.ftptgeoqa = reshape(hdfread(fn,'ftptgeoqa'), 1, nobs);
l1c.zengeoqa = reshape(hdfread(fn,'zengeoqa'), 1, nobs);
l1c.demgeoqa = reshape(hdfread(fn,'demgeoqa'), 1, nobs);
l1c.state = reshape(hdfread(fn,'state'), 1, nobs);
l1c.Rdiff_swindow = reshape(hdfread(fn,'Rdiff_swindow'), 1, nobs);
l1c.Rdiff_lwindow = reshape(hdfread(fn,'Rdiff_lwindow'), 1, nobs);
l1c.SceneInhomogeneous = reshape(hdfread(fn,'SceneInhomogeneous'), 1, nobs);
l1c.dust_flag = reshape(hdfread(fn,'dust_flag'), 1, nobs);
l1c.dust_score = reshape(hdfread(fn,'dust_score'), 1, nobs);
l1c.spectral_clear_indicator = reshape(hdfread(fn,'spectral_clear_indicator'), 1, nobs);
l1c.BT_diff_SO2 = reshape(hdfread(fn,'BT_diff_SO2'), 1, nobs);
l1c.AB_Weight = reshape(hdfread(fn,'AB_Weight'), nobs, nchan)';
l1c.L1cProc = reshape(hdfread(fn,'L1cProc'), nobs, nchan)';
l1c.L1cSynthReason = reshape(hdfread(fn,'L1cSynthReason'), nobs, nchan)';
l1c.NeN = reshape(hdfread(fn,'NeN'), nobs, nchan)';
l1c.Inhomo850 = reshape(hdfread(fn,'Inhomo850'), 1, nobs);

return