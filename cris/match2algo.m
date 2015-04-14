function algorads = match2algo(rtimes, fovids)
% MATCH2ALGO find cris algo test radiances matching rtime and FOVid
%
%
% 

ndata = length(rtimes);

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
        sfiles = dir(fullfile(apath, syear, sdoy, searchstr));

        nfiles = length(sfiles);
        for i = 1:nfiles
            tstart = str2num(sfiles(i).name(22:27));
            tend = str2num(sfiles(i).name(31:36));
            ttime = str2num(stime);

            % read GCRSO file for time comparison (This comparison
            % should be made more directly with the range encoded
            % in the filenames 
            glist = dir(['GCRSO_npp_', sid, '*.h5']);
            gtmp = glist(end).name;
            gfile = fullfile(apath, syear, sdoy, gtmp);
            [geo, gat1] = read_GCRSO(gfile)

            if ((ttime > tstart) && (ttime < tend))
                % time of observation is within this file
                keyboard
                % grab enough of filename to quickly locate GCRSO file
                % for ancillary data
                sid = sfiles(i).name(11:28);
                
                % read SCRIS file and find data point
                pd = readsdr_rawpd(sfiles(i).name);
               
                % find algo fovs matching current index fovid
                % start with simple find() on obs time
                FORTime = tai2iet(rtimes(i));
                matchindex = find(geo.FORTime == FORTime);
                
                
                % capture algo radiances in output array
                rradLW(i,:) = pd.ES_RealLW(obsid, l, fov, scan);
                rradMW(i,:) = pd.ES_RealMW(obsid, l, fov, scan);
                rradSW(i,:) = pd.ES_RealSW(obsid, l, fov, scan);
                iradLW(i,:) = pd.ES_ImaginaryLW(obsid, l, fov, scan);
                iradMW(i,:) = pd.ES_ImaginaryMW(obsid, l, fov, scan);
                iradSW(i,:) = pd.ES_ImaginarySW(obsid, l, fov, scan);
                break;
            end % end if
        end  % end for i = 1:nfiles

    end % end for j = 1:4


end

%% ****end function match2algo****