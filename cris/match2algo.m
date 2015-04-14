function algorads = match2algo(rtimes, lats, lons)
% MATCH2ALGO find cris algo test radiances matching rtime and FOVid
%
%
%

% cast rtimes from double to int64 to match GCRSO FORTime type for
% later comparison
rtimes = int64(rtimes);
ndata = length(rtimes);

algorads = struct;

% LW has 717 spectral channels
% MW has 869 spectral channels
% SW has 637 spectral channels
rradLW = zeros(ndata, 717);
iradLW = rradLW;
rradMW = zeros(ndata, 869);
iradMW = rradMW;
rradSW = zeros(ndata, 637);
iradSW = rradSW;

% FORTime -> rtime conversion from ccast2rtp.m
%prof.rtime = reshape(ones(9,1) * (geo.FORTime(:)' * 1e-6 ), 1, nobs);

% loop over the incoming list of obs to match
for i = 1:ndata

    % find algo files matching current index time
    
    tt = datetime(1958,1,1,0,0,rtimes(i));

    format = 'yyyymmdd';
    dstr = datestr(tt,format);
    
    format = 'HHMM';
    hstr = datestr(tt,format);

    format = 'HHMMSS';
    stime = datestr(tt, format);

    format = 'yyyy';
    syear = datestr(tt, format);
    
    sdoy = sprintf('%03d', day(tt, 'dayofyear'));

    % read in matching algo files
    for j = 1:4
        % build path to algo<n> files for this date
        apath = sprintf('/asl/data/cris/sdr4/algo%d',j);
        
        searchstr = sprintf('GCRSO_npp_d%s_t%s*.h5', dstr, hstr);
        gfiles = dir(fullfile(apath, syear, sdoy, searchstr));

        nfiles = length(gfiles);
        for i = 1:nfiles

            % read GCRSO file for time comparison (This comparison
            % should be made more directly with the range encoded
            % in the filenames 
            gtmp = gfiles(i).name;
            gfile = fullfile(apath, syear, sdoy, gtmp);
            [geo, gat1] = read_GCRSO(gfile)
            % -35 seconds adjusts between TAI and TAI 58 time? 
            TAITime = iet2tai(geo.FORTime)-35;
            keyboard
            if ((rtimes(i) > TAITime(1)) && (rtimes(i) < TAITime(end)))
                % time of observation is within this file
                keyboard
                % grab enough of filename to quickly locate GCRSO file
                % for ancillary data
                sid = gfiles(i).name(11:28);
                stmp = sprintf('SCRIS_npp_%s_*.h5', sid);
                sfiles = dir(fullfile(apath, syear, sdoy, stmp));
                
                % read SCRIS file and find data point
                pd = readsdr_rawpd(fullfile(apath, syear, sdoy, sfiles(1).name));
               
                % find algo fovs matching current index fovid
                % start with simple find() on obs time
                keyboard
                [fregard, scan] = find(TAITime == rtimes(i));

                % now isolate fov by matching to input lat/lon
                for k = 1:length(fregard)
                    
                end
                
                % capture algo radiances in output array
                algorads.algo(j).rradLW(i,:) = pd.ES_RealLW(:, fov, fregard, scan);
                algorads.algo(j).rradMW(i,:) = pd.ES_RealMW(:, fov, fregard, scan);
                algorads.algo(j).rradSW(i,:) = pd.ES_RealSW(:, fov, fregard, scan);
                algorads.algo(j).iradLW(i,:) = pd.ES_ImaginaryLW(:, fov, fregard, scan);
                algorads.algo(j).iradMW(i,:) = pd.ES_ImaginaryMW(:, fov, fregard, scan);
                algorads.algo(j).iradSW(i,:) = pd.ES_ImaginarySW(:, fov, fregard, scan);
                break;
            end % end if
        end  % end for i = 1:nfiles
            
    end % end for j = 1:4


end

%% ****end function match2algo****