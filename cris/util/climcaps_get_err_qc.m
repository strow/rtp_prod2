function climcaps_get_err_qc(year, month, day)
% Read in a day's worth of CLIMCAPS CCR netcdf data and pull out
% data to match obs in climcaps ccr random rtp file
rtp_addpaths
addpath ~/git/rtp_prod2_DEV/cris/readers
addpath ~/git/rtp_prod2_DEV/util

% generate doy
dt = datetime(year, month, day);
dt.Format = 'DDD';

rtpbase='/asl/isilon/rtp/climcaps_snpp_ccr_hires/random';
ccrbase='/umbc/xfs3/strow/asl/CLIMCAPS_SNDR_SNPP_CCR/FSR';

% corresponding random rtp file
% $$$ climcapsrtpfile=['/asl/isilon/rtp/climcaps_snpp_ccr_hires/random/' ...
% $$$                  '2018/003/SNDR.SNPP.CRIMSS_20180103_random.rtp'];
climcapsrtpfile=sprintf('%s/%4d/%s/SNDR.SNPP.CRIMSS_%4d%02d%02d_random.rtp', ...
                        rtpbase, year, dt, year,month,day);
fprintf(1, '> CLIMCAPS random rtp file: %s\n', climcapsrtpfile);

% specify output file path and name
% $$$ outfile = '/home/sbuczko1/Work/climcaps/climcaps_ccr_20180103_rad_mw';
outfile = sprintf('%s/%4d/%s/climcaps_ccr_%4d%02d%02d_rad_qc_err', ...
                  rtpbase, year, dt, year, month, day);
fprintf(1, '> Output to %s.mat\n', outfile);

% read in day of files
% $$$ climcapsncdir=['/umbc/xfs3/strow/asl/CLIMCAPS_SNDR_SNPP_CCR/FSR/2018/' ...
% $$$              '01/03'];
climcapsncdir = sprintf('%s/%4d/%02d/%02d', ccrbase, year, month, ...
                        day);
fprintf(1, '> Looking for input files in %s\n', climcapsncdir);

climcapsncfiles=dir(fullfile(climcapsncdir, ['SNDR.SNPP.CRIMSS.*' ...
                    '.nc']));
nfiles=length(climcapsncfiles);
fprintf(1, '> Found %d CLIMCAPS netcdf files to process\n', ...
        nfiles);

firstpass = true;
for i=1:nfiles
    s = read_climcaps(fullfile(climcapsncfiles(i).folder, ...
                               climcapsncfiles(i).name));

    % grab lat, lon, and rtime to intersect against and rad_mw,
    % rad_mw_qc, and rad_mw_err to report
    nobs = 30*45;
    trlat = single(reshape(s.lat, 1, nobs));
    trlon = single(reshape(s.lon, 1, nobs));

    % Obs times are TAI93 times (like AIRS) but need to be TAI58 for
    % consistency wth other downstream processing
    temp = reshape(airs2tai(s.obs_time_tai93), 1, nobs);
    trtime = reshape(temp, 1, nobs);
    clear temp;

    % might also want xtrack/atrack to intersect against
    iobs = 1:nobs;
    tatrack = int32( 1 + floor((iobs-1)/30) );
    txtrack = int32( 1 + mod((iobs-1),30) );

    % read in the radiance related values
    [vSW,~] = size(s.wnum_sw);
    trad_sw = reshape(s.rad_sw, vSW, nobs);
    trad_sw_err = reshape(s.rad_sw_err, vSW, nobs);
    trad_sw_qc = reshape(s.rad_sw_qc, vSW, nobs);
    [vMW,~] = size(s.wnum_mw);
    trad_mw = reshape(s.rad_mw, vMW, nobs);
    trad_mw_err = reshape(s.rad_mw_err, vMW, nobs);
    trad_mw_qc = reshape(s.rad_mw_qc, vMW, nobs);
    [vLW,~] = size(s.wnum_lw);
    trad_lw = reshape(s.rad_lw, vLW, nobs);
    trad_lw_err = reshape(s.rad_lw_err, vLW, nobs);
    trad_lw_qc = reshape(s.rad_lw_qc, vLW, nobs);

    if firstpass
        rrlat = trlat;
        rrlon = trlon;
        rrtime = trtime;
        ratrack = tatrack;
        rxtrack = txtrack;
        rrad_sw = trad_sw;
        rrad_sw_err = trad_sw_err;
        rrad_sw_qc = trad_sw_qc;
        rrad_mw = trad_mw;
        rrad_mw_err = trad_mw_err;
        rrad_mw_qc = trad_mw_qc;
        rrad_lw = trad_lw;
        rrad_lw_err = trad_lw_err;
        rrad_lw_qc = trad_lw_qc;
        firstpass = false;
    else
        rrlat = cat(2, rrlat, trlat);
        rrlon = cat(2, rrlon, trlon);
        rrtime = cat(2, rrtime, trtime);
        ratrack = cat(2, ratrack, tatrack);
        rxtrack = cat(2, rxtrack, txtrack);
        rrad_sw = cat(2, rrad_sw, trad_sw);
        rrad_sw_err = cat(2, rrad_sw_err, trad_sw_err);
        rrad_sw_qc = cat(2, rrad_sw_qc, trad_sw_qc);
        rrad_mw = cat(2, rrad_mw, trad_mw);
        rrad_mw_err = cat(2, rrad_mw_err, trad_mw_err);
        rrad_mw_qc = cat(2, rrad_mw_qc, trad_mw_qc);
        rrad_lw = cat(2, rrad_lw, trad_lw);
        rrad_lw_err = cat(2, rrad_lw_err, trad_lw_err);
        rrad_lw_qc = cat(2, rrad_lw_qc, trad_lw_qc);
    end % end concatenation block

end % end loop over netcdf files
fprintf(1, '> netcdf files read in and concatenated\n');

% read in rtp file
fprintf(1, '> Read in corresponding rtp file\n');
[~,~,p,~] = rtpread(climcapsrtpfile);

fprintf(1, '> Building data tables for intersection\n');
Fobs = table(ratrack', rxtrack', rrtime', 'VariableNames', {'atrack' ...
                    'xtrack' 'rtime'});
Robs = table(p.atrack', p.xtrack', p.rtime', 'VariableNames', {'atrack' ...
                    'xtrack' 'rtime'});

[C, ia, ib] = intersect(Robs, Fobs, 'stable');

rlat = rrlat(ib);
rlon = rrlon(ib);
rtime = rrtime(ib);
atrack = ratrack(ib);
xtrack = rxtrack(ib);
rad_sw = rrad_sw(:,ib);
rad_sw_err = rrad_sw_err(:,ib);
rad_sw_qc = rrad_sw_qc(:,ib);
rad_mw = rrad_mw(:,ib);
rad_mw_err = rrad_mw_err(:,ib);
rad_mw_qc = rrad_mw_qc(:,ib);
rad_lw = rrad_lw(:,ib);
rad_lw_err = rrad_lw_err(:,ib);
rad_lw_qc = rrad_lw_qc(:,ib);

save(outfile, 'rlat', 'rlon', 'rtime', 'atrack', 'xtrack', 'rad_sw', ...
            'rad_sw_err', 'rad_sw_qc','rad_mw', ...
            'rad_mw_err', 'rad_mw_qc','rad_lw', ...
            'rad_lw_err', 'rad_lw_qc');

