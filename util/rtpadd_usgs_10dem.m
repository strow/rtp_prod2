function [h ha p pa] = rtpadd_usgs_10dem(h,ha,p,pa,root)
% Add USGS land fraction and surface altitude to an RTP structure.
% function [h,ha,p,pa] = rtpadd_usgs_10dem(h,ha,p,pa,root)
%
%   Add or replace "landfrac" and "salti" profile fields using the
%   USGS 10deg landfrac/salti data base. 
% 
%   h,ha,p,pa - rtp structure
% 
%   root - optional: root directory (usually /asl) of where to find 
%                    the USGS data file. 
%          None - /asl/data/usgs/world_grid_deg10_v2.mat
%          dir  - dir/data/usgs/world_grid_deg10_v2.mat
%          mfile - use the matfile "mfile" as the usgs database.
% 
%   Default USGS matlab file: /asl/data/usgs/world_grid_deg10_v2.mat
%
% Add surface altitude and land fraction based on the usgs_10dem.m data.
% Invalid Lats and Lons will be ignored and marked as -9999;
%
% If fields "landfrac" or "salti" already exist, move them to udefs.
% 
% Breno Imbiriba - 2013.03.14

  if(~exist('root','var'))
    wgf = '/asl/models/usgs/world_grid_deg10_v2.mat';
  elseif(exist(root,'dir'))
    wgf = [root '/models/usgs/world_grid_deg10_v2.mat'];
  elseif(exist(root,'file'))
    wgf = root;
  else
    error(['Your "root" argument is invalid: ' root ]);
  end

% Only if debug
%  disp(['rtpadd_usgs_10dem.m: Using ' wgf ' as landfrac/salti database.']);

  % If there's any bad GEO data, replace it by the (0,0) so not to crash
  % usgs_deg10_dem.m. 
  ibad_geo = find(abs(p.rlat)>90 | p.rlon<-180 | p.rlon>360 | isnan(p.rlat) | isnan(p.rlon));
  bad_rlat = p.rlat(ibad_geo);
  bad_rlon = p.rlon(ibad_geo);
  p.rlat(ibad_geo) = 0; 
  p.rlon(ibad_geo) = 0;

  % Call main geo routine
  [salti landfrac] = usgs_deg10_dem(p.rlat, p.rlon,wgf);


  % Treatement of pre-existing salti/landfrac:

  % Check if pre-existig salti or landfrac are present:
  lsalti = false;
  llandfrac = false;
  if(isfield(p,'salti'))
    lsalti = p.salti>-100 & ~isnan(p.salti);
  end 
  if(isfield(p,'landfrac'))
    llandfrac = p.landfrac>-1 & ~isnan(p.landfrac);
  end


  % If landfrac pre-exists, move it to a udef.
  if(any(llandfrac))
    % Grab it's attribute (it it exists)
    lfname = get_attr(pa,'landfrac'); 

    % Copy it to a udef:
    [p pa] = setudef(p, pa, p.landfrac, 'landfrac', lfname,'udef');
  end
 
  % If salti pre-exists, move it to a udef.
  if(any(lsalti))
    % Grab it's attribute (it it exists)
    lfname = get_attr(pa,'salti'); 

    % Copy it to a udef:
    [p pa] = setudef(p, pa, p.salti, 'salti', lfname,'udef');
  end



  % Now, replace the data in the main RTP structure. 
  p.salti=single(salti);
  p.landfrac=single(landfrac);

  pa = set_attr(pa, 'landfrac','USGS Land Fraction');
  pa = set_attr(pa, 'salti','USGS surface altitude');

  % Replace bad points by -9999
  p.rlat(ibad_geo) = bad_rlat;
  p.rlon(ibad_geo) = bad_rlon;
  p.salti(ibad_geo)    = -9999;
  p.landfrac(ibad_geo) = -9999;


  ha=set_attr(ha,'topo','usgs_deg10_dem');

end

