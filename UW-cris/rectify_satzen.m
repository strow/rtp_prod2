function sat_zen = rectify_satzen(s, nfile)

[nfovs, nfors, nscans] = size(s.sat_zen);
nobs = nfovs * nfors * nscans;

% UW granules come with names in nfile of the form:
% SNDR.J1.CRIS.20180121T2218.m06.g224.L1B.nc
%
% The 'T????' matches to time in ccast allfov rtp granules
[spath, sfile, ext] = fileparts(nfile);
tstamp = sfile(23:26);

% use tstamp to select corresponding granule from our ccast
% processing (but we'll grab from the rtp output). This presumes
% that granules match one-to-one. Hopefully this holds.
rtpdir = ['/asl/rtp/rtp_cris2_ccast_hires_j1v3_a2v3/allfov/2018/' ...
          '021'];
rfile = 'cris2_ecmwf_csarta_allfov_d20180121_t%s010.rtp';
rtpfile = fullfile(rtpdir, sprintf(rfile, tstamp));

[~,~,p,~] = rtpread(rtpfile);
rnobs = length(p.rtime);
if nobs ~= rnobs
    fprintf(['** Number of obs differs between UW and ccast granules ' ...
             'for %s **\n'], nfile);
    return
end

% $$$ % reshape UW TAI time, lat and lon to straight arrays
% $$$ temp = reshape(airs2tai(s.obs_time_tai93), 1, nfors*nscans);
% $$$ rtime = reshape(ones(9,1)*temp, 1, nobs);
% $$$ clear temp
% $$$ rlat = reshape(s.lat, 1, nobs);
% $$$ rlon = reshape(s.lon, 1, nobs);
% $$$ 
% $$$ % build table structures of rtime, rlat and rlon for both UW and
% $$$ % ccast data to intersect
% $$$ UWobs = table(rtime', rlat', rlon');
% $$$ CCobs = table(p.rtime', p.rlat', p.rlon');
% $$$ 
% $$$ [C, ia, ib] = intersect(UWobs, CCobs);

%%%%%%%%
sat_zen = p.satzen;
