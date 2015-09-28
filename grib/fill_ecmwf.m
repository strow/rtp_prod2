% fill_ecmwf.m
% 
% L. Strow, 22 Oct 2014
%
% Modify to include era?

function [prof, head, pattr] = fill_ecmwf(prof, head, pattr);

% Check args in and out to see if they conform to the new API and
% aren't split between old and new styles
if nargin ~= nargout
    error(['>>> ERROR: mismatch between fill_ecmwf inputs and ' ...
           'outputs.\n\tUse either [p,h]=fill_ecmwf(p,h) or ' ...
           '[p,h,pa]=fill_ecmwf(p,h,pa) (preferred)\n\tTerminating'], '\n');
end

addpath /asl/matlib/aslutil
addpath /asl/packages/time

% Location of grib files
fhdr = '/asl/data/ecmwf_nc/';

ename = '';  % This should be placed outside a rtp file loop

mtime = tai2dnum(prof.rtime);

% Get a cell array of ecmwf grib files for each time
% I think this will be BROKEN if using datetime above!!
enames = get_ecmwf_enames(mtime);

% Find the unique grib files and indices that go with them
[u_enames, ia, ic] = unique(enames);
n = length(u_enames);

% Loop over unique grib file names
for i = 1:n
% Build file name from parts
   fne = ['UAD' u_enames{i} '001'];
   e_mth_year = datestr(mtime(ia(i)),'yyyymm');
   fn = fullfile(fhdr,e_mth_year(1:4),e_mth_year(5:6),fne);
% Actually read grib1, grib2 .nc files
   fn_s = [fn '-1.nc'];
   fn_h = [fn '-2.nc'];
% Do the netcdf files exist?
   if exist(fn_s) == 0 | exist(fn_h) == 0 
      disp(['Netcdf grib files missing for root: ' fn])
      break % Go to next partition
   end
% If the filename has changed, re-load F   
%keyboard
   if ~strcmp(ename,fn) 
      clear F  % Probably not needed
      disp('New file')
      F = grib_interpolate(fn_s,fn_h);
      ename = fn;
   end   
% Fill rtp fields
   k = find( ic == i );  % indices of first partition (of n total)
% Assume rtp lat/lon are +-180??  Need to be 0-360 for grib interpolation
   rlat = prof.rlat(k);
   rlon = prof.rlon(k);
   rlon(rlon<0) = rlon(rlon<0) + 360;

   prof.sst(k)     = F.sst.ig(rlat,rlon);
   prof.spres(k)   = F.sp.ig(rlat,rlon);
   prof.stemp(k)   = F.skt.ig(rlat,rlon);
   wind_v          = F.v10.ig(rlat,rlon);
   wind_u          = F.u10.ig(rlat,rlon);
   prof.wspeed(k)  = sqrt(wind_u.^2 + wind_v).^2;
   prof.wsource(k) = mod(atan2(single(wind_u), single(wind_v)) * 180/pi,360);
   prof.tcc(k)   = F.tcc.ig(rlat,rlon);
   ci_udef = 1;
   prof.udef(ci_udef,k) = F.ci.ig(rlat,rlon);
   % Estimate model grid centers used
   gdlat = abs(nanmean(diff(F.h_latitude)));  % lat spacing
   gdlon = abs(nanmean(diff(F.h_longitude))); % lon spacing
   prof.plat(k) = floor(rlat/gdlat)*gdlat + gdlat/2;
   prof.plon(k) = floor(rlon/gdlon)*gdlon + gdlon/2;

% F.tcwv.ig  % Total column water?  Use this instead of ours (Sergio?)?
% F.msl.ig   % Not in rtp for now

% Hybrid parameters
% levid = 1 is top of atmosphere
% b are the sortedd level IDs   
%   prof.nlevs = ones(1,length(k))*length(F.levid);
   [b,j]=sort(F.levid);
   for l=1:length(F.levid)
      prof.ptemp(l,k) = F.t(j(l)).ig(rlat,rlon);
      prof.gas_1(l,k) = F.q(j(l)).ig(rlat,rlon);
      prof.gas_3(l,k) = F.o3(j(l)).ig(rlat,rlon);
      prof.cc(l,k)    = F.cc(j(l)).ig(rlat,rlon);
      prof.clwc(l,k)  = F.clwc(j(l)).ig(rlat,rlon);
      prof.ciwc(l,k)  = F.ciwc(j(l)).ig(rlat,rlon);
   end
% Only want pressure levels in grib file, in order
% Is this a 91 or 137 level forecast?
% Note: On June 25, 2013 ECMWF moved to 137 levels, and they selected
% 91 of these to send to us!!  Need to map them correctly!
% Need to check, how many levels in Sept. 1, 2092 ECMWF?
   max_lev = max(F.levid);
   if max_lev > 91
      xtemp = p137_ecmwf(prof.spres(k));
   else
      xtemp = p91_ecmwf(prof.spres(k));
   end
   prof.plevs(:,k) = xtemp(b,:);  % subset to ones in grib file
   prof.nlevs(k) = length(F.levid);
end
prof.nlevs = int32(prof.nlevs);

% Header info
head.ptype = 0;
head.ngas = 2;
head.glist = [1; 3];
head.gunit = [21; 21];
head.pmin = min( prof.plevs(1,:) );
head.pmax = max( prof.plevs(end,:) );
% Setting attributes needs work...
% pattr = set_attr(pattr,'profiles','ECMWF','profiles');

% I think this is needed to avoid negatives in SARTA?
min_H2O_gg = 3.1E-7;  % 0.5 pppm
min_O3_gg = 1.6E-8;   % 0.01 ppm
% Find/replace bad mixing ratios
if isfield(prof,'gas_1')
  ibad = find(prof.gas_1 <= 0);
  nbad = length(ibad);
  if (nbad > 0)
    prof.gas_1(ibad) = min_H2O_gg;
%    say(['Replaced ' int2str(nbad) ' negative/zero H2O mixing ratios'])
  end
end
%
if isfield(prof,'gas_3')
  ibad = find(prof.gas_3 <= 0);
  nbad = length(ibad);
  if (nbad > 0)
    prof.gas_3(ibad) = min_O3_gg;
%    say(['Replaced ' int2str(nbad) ' negative/zero O3 mixing ratios'])
  end
end
%  fix any cloud frac
if isfield(prof,'tcc')
  ibad = find(prof.tcc > 1);
  nbad = length(ibad);
  if (nbad > 0)
    prof.tcc(ibad) = 1;
%    say(['Replaced ' int2str(nbad) ' TCC > 1 fields'])
  end
end

switch nargin
  case 2
    fprintf(2, ['>>> WARNING: fill_ecmwf now sets model attribute in ' ...
                'pattr.\n\tUpdate calls to fill_ecmwf to include pattr. ' ...
                'i.e. [p,h,pa] = fill_ecmwf(p,h,pa)\n'])
  case 3
    % set an attribute string to let the rtp know what we have done
    pattr = set_attr(pattr,'model','ecmwf');
end
