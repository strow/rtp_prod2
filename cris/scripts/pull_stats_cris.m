function pull_stats_cris(year)

%**************************************************
% need to make this work on daily concat files: look for loop over
% granules, this will need to be removed. Also break out by fov
% (add loop and index over p.ifov)
%
% following the 'file in; file out' standard, this routine will
% read in ONE daily concatenated rtp file and calculate its
% stats. There will be a driver function above this that will feed
% rtp file paths to this routine and can provide for slurm indexing
% and chunking
%**************************************************

addpath /asl/matlib/h4tools
addpath /asl/rtp_prod/airs/utils
addpath /asl/packages/ccast/motmsc/utils/
addpath ~/git/rtp_prod2/util
addpath   /asl/rtp_prod/cris/unapod

%year = 2012;

% Get proper frequencies for these data
[n1,n2,n3,userLW,userMW,userSW, ichan] = cris_lowres_chans();
f = cris_vchan(2, userLW, userMW, userSW);

basedir = fullfile('/asl/data/rtp_cris_ccast_lores/clear_daily', ...
                   int2str(year));
dayfiles = dir(fullfile(basedir, 'rtp*_clear.rtp'));

for iday = 1:length(dayfiles)
    fprintf(1, '>>> year = %d  :: iday = %d\n', year, iday);
    
    % Get daily average
    % Initialize mean, std running mean (per day)
    %  m_init  = zeros(1,2223);  
    m_init  = zeros(1,1317); 
    m   = m_init; w   = m_init; n   = m_init;
    mo  = m_init; wo  = m_init; no  = m_init;
    mc  = m_init; wc  = m_init; nc  = m_init;
    mco = m_init; wco = m_init; nco = m_init;
    mb  = m_init; wb  = m_init; nb  = m_init;
    mt = 0;       wt = 0;       nt = 0;

    if dayfiles(iday).bytes > 21509  % Length of rtp if no scenes
        [h,ha,p,pa] = rtpread(fullfile(basedir,dayfiles(iday).name));
        % Subset here if needed
        
        %**************************************************
        % the following line is the majority of the business
        % logic here. this line will change frequently: can we
        % encapsulate so that this change does not require
        % editing this file (thinking something like function
        % pointer in C?)
        %**************************************************
        k = find( abs(p.rlat) < 30 & p.landfrac == 0 & (p.xtrack == 15 | p.xtrack == 16) & p.solzen > 90);
        if length(k) >= 2       % tropical granule over ocean
            p = rtp_sub_prof(p, k);
            for z = 1:9  % loop over FOVs to further sub-select
                ifov = find(p.ifov == z);
                p2 = rtp_sub_prof(p, ifov);
                % Loop over obs in day
                for j=1:length(p2.rlat)
                    % Radiance mean and std
                    r  = p2.robs1(:,j);
                    rc = p2.rcalc(:,j);
                    % Convert r to rham
                    r = box_to_ham(r);  % assumes r in freq order!!
                    r = r';
                    rc = rc';
                    % Recursive mean and std for robs, rcal
                    [m, w, n] = rec_var(m,w,n,r);
                    [mc, wc, nc] = rec_var(mc,wc,nc,rc);
                    % B(T) bias mean and std
                    btobs = real(rad2bt(f,r));
                    btcal = real(rad2bt(f,rc));
                    bias  = btobs-btcal;
                    % Recursive mean and std for bias
                    [mb, wb, nb] = rec_var(mb,wb,nb,bias);
                    % Recursive mean and std for rtime
                    [mt, wt, nt] = rec_var(mt,wt,nt,p2.rtime(j));
                end  % loop over obs in day
                lat_mean = nanmean(p2.rlat);
                lon_mean = nanmean(p2.rlon);
                solzen_mean = nanmean(p2.solzen);
                rtime_mean  = nanmean(p2.rtime);
            end  % if Tropical
        end  % if file not empty
        rvar              = w ./ (n - 1);
        rstd(iday,:)      = sqrt(rvar);
        rmean(iday,:)     = m;
        rcalmean(iday,:)  = mc;

        bvar              = wb ./ (nb -1);
        bias_std(iday,z,:)  = sqrt(bvar);
        bias_mean(iday,z,:) = mb;
        all_rtime(iday,z)   = mt;

        all_rlat(iday,z)    = lat_mean;
        all_rlon(iday,z)    = lon_mean;
        all_solzen(iday,z)  = solzen_mean;
        all_count(iday,z)   = nanmean(n);
    end  % end loop over FOVs
end  % Day loop
eval_str = ['save ~/testoutput/rtp_cris_lores'  int2str(year)  ' rmean rcalmean bias_mean  bias_std rstd  all_*'];
eval(eval_str);
