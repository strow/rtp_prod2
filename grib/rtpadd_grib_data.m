function [head, hattr, prof, pattr] = rtpadd_grib_data(sourcename, head, hattr, prof, pattr, fields, rec_per_day, center_long);

% function [head, hattr, prof, pattr] = rtpadd_grib_data(sourcename, head, hattr, prof, pattr);
% function [head, hattr, prof, pattr] = rtpadd_grib_data(sourcename, head, hattr, prof, pattr, fields, rec_per_day, center_long);
%
% Routine to read in a 37, 60, or 91 level ECMWF file and return a
% RTP-like structure of profiles that are the closest grid points
% to the specified (lat,lon) locations.
%
% Input:
%    sourcename : (string) complete ECMWG GRIB file name
%                to automatically pick files use either 'ECMWF' or 'ERA'
%    head      : rtp header structure
%    hattr     : header attributes
%    prof.       profile structure with the following fields
%        rlat  : (1 x nprof) latitudes (degrees -90 to +90)
%        rlon  : (1 x nprof) longitude (degrees, either 0 to 360 or -180 to 180)
%        rtime : (1 x nprof) observation time in seconds
%    pattr     : profile attributes, note: rtime must be specified
%    OPTIONAL
%    fields    : list of fields to consider when populating the rtp profiles:
%                 {'SP','SKT','10U','10V','TCC','CI','T','Q','O3','CC','CIWC','CLWC'}
%               default:  {'SP','SKT','10U','10V','TCC','CI','T','Q','O3'}
%    rec_per_day : number of ECMWF time steps per day {default=8}
%    center_long : center of grib longitude values
%
% Output:
%    head : (RTP "head" structure of header info)
%    hattr: header attributes
%    prof : (RTP "prof" structure of profile info)
%    pattr: profile attributes
%
% Note: uses external routines: p60_ecmwf.m, p91_ecmwf.m, readgrib_inv_data.m,
%    readgrib_offset_data.m, as well as the "wgrib" program.
%

% Created: 17 Mar 2006, Scott Hannon - re-write of old 60 level version
% Rewrite:  4 May 2011, Paul Schou - switched to matlab binary reader
% Update : 17 Jun 2011, Paul Schou - added grib 2 capabilities
% Update: 27 Jun 2011, S.Hannon - add isfield test for head.pfields
% Update: 05 Jan 2012, L. Strow - bitor argument translated to uint32

  min_H2O_gg = 3.1E-7;  % 0.5 pppm
  min_O3_gg = 1.6E-8;   % 0.01 ppm

    % assign the field to the correct profile field
    switch param{irec}
      % Parameter "SP" surface pressure (Pa)
      case 'SP'; if ~isfield(prof,'spres'); prof.spres = nan(1,nprof,'single'); end
	prof.spres(1,idate) = d(iprof(idate)) / 100;  % convert Pa to hPa=mb

      % Parameter "SKT" skin temperature (K)
      case 'SKT'; if ~isfield(prof,'stemp'); prof.stemp = nan(1,nprof,'single'); end
	prof.stemp(1,idate) = d(iprof(idate));
	%say(['skt ' num2str(sum(idate))])
	
      % Parameter "SSTK" skin temperature (K)
      case 'SSTK'; if ~isfield(prof,'sstk'); prof.sstk = nan(1,nprof,'single'); end
	prof.sstk(1,idate) = d(iprof(idate));
	%say(['skt ' num2str(sum(idate))])
	
      % Parameter "10U"/"10V" 10 meter u/v wind component (m/s)
      case '10U'; if ~exist('wind_u','var'); wind_u = nan(1,nprof,'single'); end
	wind_u(1,idate) = d(iprof(idate));
	%say(['setting 10U for ' num2str(sum(idate))])
      case '10V'; if ~exist('wind_v','var'); wind_v = nan(1,nprof,'single'); end
	wind_v(1,idate) = d(iprof(idate));
	%say(['setting 10V for ' num2str(sum(idate))])

      % Parameter "TCC" total cloud cover (0-1)
      case 'TCC'; if ~isfield(prof,'cfrac'); prof.cfrac = nan(1,nprof,'single'); end
	prof.cfrac(1,idate) = d(iprof(idate));
	if any(prof.cfrac > 1)
	  say('Warning: cloud frac > 1')
	  %if strcmp(getenv('USER'),'schou'); keyboard; end
	end

      % Parameter "CI" sea ice cover (0-1)
      case 'CI'; 
	%if ~isempty(getenv('TEST')); keyboard; end
	prof.udef(ci_udef,idate) = d(iprof(idate));

      % Parameter "T" temperature (K)
      case 'T'; if ~isfield(prof,'ptemp') | size(prof.ptemp,1) ~= nlev; prof.ptemp = nan(nlev,nprof,'single'); end
	prof.ptemp(find(levs == level(irec)),idate) = d(iprof(idate));
	%say('t')

      % Parameter "Q" specific humidity (kg/kg)
      case 'Q'; if ~isfield(prof,'gas_1') | size(prof.gas_1,1) ~= nlev; prof.gas_1 = nan(nlev,nprof,'single'); end
	prof.gas_1(find(levs == level(irec)),idate) = d(iprof(idate));
	  %if any(d(:) <= 0) & strcmp(getenv('USER'),'schou'); say('Q < 0!!'); keyboard; end
	% WARNING! ECMWF water is probably specific humidity rather than mixing ratio,
	% in which case this code should do: gas_1 = gas_1 / (1 - gas_1).

      % Parameter "O3" ozone mass mixing ratio (kg/kg)
      case 'O3'; if ~isfield(prof,'gas_3') | size(prof.gas_3,1) ~= nlev; prof.gas_3 = nan(nlev,nprof,'single'); end
	prof.gas_3(find(levs == level(irec)),idate) = d(iprof(idate));
	  %if any(d(:) <= 0) & strcmp(getenv('USER'),'schou'); say('O3 < 0!!'); keyboard; end

      % Parameter "CC" cloud cover (0-1) 
      case 'CC'; if ~isfield(prof,'cc') | size(prof.cc,1) ~= nlev; prof.cc = nan(nlev,nprof,'single'); end
	prof.cc(find(levs == level(irec)),idate) = d(iprof(idate));

      % Parameter "CIWC" cloud ice water content kg/kg 
      case 'CIWC'; if ~isfield(prof,'ciwc') | size(prof.ciwc,1) ~= nlev; prof.ciwc = nan(nlev,nprof,'single'); end
	prof.ciwc(find(levs == level(irec)),idate) = d(iprof(idate));

      % Parameter "CLWC" cloud liquid water content kg/kg 
      case 'CLWC'; if ~isfield(prof,'clwc') | size(prof.clwc,1) ~= nlev; prof.clwc = nan(nlev,nprof,'single'); end
	prof.clwc(find(levs == level(irec)),idate) = d(iprof(idate));

      otherwise
	if ~isfield(prof,['grib_' param{irec}]) | size(prof.(['grib_' param{irec}]),1) ~= nlev; prof.(['grib_' param{irec}]) = nan(nlev,nprof,'single'); end
	prof.(['grib_' param{irec}])(find(levs == level(irec)),idate) = d(iprof(idate));
    end
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read wind data & convert
  %%%%%%%%%%%%%%%%%%%%%%%%%%

  if exist('wind_u','var') & exist('wind_v','var')
    i = ~isnan(wind_u);
    prof.wspeed(i) = sqrt(wind_u(i).^2 + wind_v(i).^2);
    prof.wsource(i) = mod(atan2(single(wind_u(i)), single(wind_v(i))) * 180/pi,360);
  end


  % Calculate the pressure levels (using p60_ecmwf.m & p91_ecmwf.m)
  if isfield(prof,'spres') & nlev > 1
    prof.nlevs = nlev*ones(1,nprof);
    pstr = ['prof.plevs=p' int2str(nlev) '_ecmwf( prof.spres );'];
    eval(pstr);
    head.pmin = min( prof.plevs(1,:) );
    head.pmax = max( prof.plevs(nlev,:) );
  else
    levels = [1 2 3 5 7 10 20 30 50 70 100 125 150 175 200 225 250 300 350 400 450 500 550 600 650 700 750 775 800 825 850 875 900 925 950 975 1000];
    prof.nlevs = length(levels)*ones(1,nprof);
    prof.plevs = repmat(levels(:),[1 length(prof.rtime)]);
    head.pmin = min( levels );
    head.pmax = max( levels );
  end

  % Assign the output header structure
  head.ptype = 0;
  if (isfield(head,'pfields'))
     head.pfields = bitor(uint32(head.pfields), 1);
  else
     head.pfields = 1;
  end
  head.ngas = 2;
  head.glist = [1; 3];
  head.gunit = [21; 21];
  %head.nchan = 0;
  %head.mwnchan = 0;



  % Find/replace bad mixing ratios
  if isfield(prof,'gas_1')
    ibad = find(prof.gas_1 <= 0);
    nbad = length(ibad);
    if (nbad > 0)
      prof.gas_1(ibad) = min_H2O_gg;
      say(['Replaced ' int2str(nbad) ' negative/zero H2O mixing ratios'])
    end
  end
  %
  if isfield(prof,'gas_3')
    ibad = find(prof.gas_3 <= 0);
    nbad = length(ibad);
    if (nbad > 0)
      prof.gas_3(ibad) = min_O3_gg;
      say(['Replaced ' int2str(nbad) ' negative/zero O3 mixing ratios'])
    end
  end
  %  fix any cloud frac
  if isfield(prof,'cfrac')
    ibad = find(prof.cfrac > 1);
    nbad = length(ibad);
    if (nbad > 0)
      prof.cfrac(ibad) = 1;
      say(['Replaced ' int2str(nbad) ' CFRAC > 1 fields'])
    end
  end

