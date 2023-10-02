function climcaps_ccpret_get_err_qc(year, month, day)
% Read in a day's worth of CLIMCAPS CCR netcdf data and pull out
% data to match obs in climcaps ccr random rtp file
rtp_addpaths
addpath ~/git/rtp_prod2_DEV/cris/readers
addpath ~/git/rtp_prod2_DEV/util

% generate doy
dt = datetime(year, month, day);
dt.Format = 'DDD';

rtpbase='/asl/isilon/rtp/climcaps_snpp_ccr_hires/random';
ccrbase='/umbc/xfs3/strow/asl/CLIMCAPS_SNDR_SNPP_CCPRET/FSR';

% corresponding random rtp file
% $$$ climcapsrtpfile=['/asl/isilon/rtp/climcaps_snpp_ccr_hires/random/' ...
% $$$                  '2018/003/SNDR.SNPP.CRIMSS_20180103_random.rtp'];
climcapsrtpfile=sprintf('%s/%4d/%s/SNDR.SNPP.CRIMSS_%4d%02d%02d_random.rtp', ...
                        rtpbase, year, dt, year,month,day);
fprintf(1, '> CLIMCAPS random rtp file: %s\n', climcapsrtpfile);

% specify output file path and name
% $$$ outfile = '/home/sbuczko1/Work/climcaps/climcaps_ccr_20180103_rad_mw';
outfile = sprintf('%s/%4d/%s/climcaps_ccpret_%4d%02d%02d_qc_err', ...
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

    % READ IN VARIABLES OF INTEREST
    tair_temp_qc = reshape(s.air_temp_qc, 100, nobs);
    tair_temp_err = reshape(s.air_temp_err, 100, nobs);

    if firstpass
        rrlat = trlat;
        rrlon = trlon;
        rrtime = trtime;
        ratrack = tatrack;
        rxtrack = txtrack;
        
        % MODIFY VARIABLES OF INTEREST HERE
        rair_temp_qc = tair_temp_qc;
        rair_temp_err = tair_temp_err;

        firstpass = false;
    else
        rrlat = cat(2, rrlat, trlat);
        rrlon = cat(2, rrlon, trlon);
        rrtime = cat(2, rrtime, trtime);
        ratrack = cat(2, ratrack, tatrack);
        rxtrack = cat(2, rxtrack, txtrack);

        % CONCATENATE VARIABLES OF INTEREST
        rair_temp_qc = cat(2, rair_temp_qc, tair_temp_qc);
        rair_temp_err = cat(2, rair_temp_err, tair_temp_err);

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

% SELECT MATCHING OBS FROM VARIABLES OF INTEREST
air_temp_qc = rair_temp_qc(:,ib);
air_temp_err = rair_temp_err(:,ib);

save(outfile, 'rlat', 'rlon', 'rtime', 'atrack', 'xtrack', ...
     'air_temp_qc', 'air_temp_err');
