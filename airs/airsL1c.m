% quick script to read AIRS L1C data into existing AIRXBCAL rtp
% files

% read AIRXBCAL clear rtp file
xbcalpath = '/asl/data/rtp_airxbcal_v5/2015/clear';
sdoy = '050';
sDate = '2015/02/19';
filepath = fullfile(xbcalpath, ['era_airxbcal_day' sdoy ...
                    '_clear.rtp']);
[h,ha,p,pa] = rtpread(filepath);

% loop on granule number (findex)
findex = p.findex;
l1cobs = zeros(2645,1);
k=1;
for i = 1:240
    % find AIRXBCAL obs corresponding to current findex
    gran_obs = find(findex == i);
    if length(gran_obs) == 0
        % nothing in AIRXBCAL for this granule
        continue;
    end

    % find position info for each obs in granule
    atracks = p.atrack(gran_obs);
    xtracks = p.xtrack(gran_obs);

    % find and read L1C file corresponding to granule number (findex)
    Lonec = read_airs_caf(sDate, i);

    L1crad = Lonec.ra;  % 2645 x 90 x 135

    % loop over gran_obs
    for j = 1:length(gran_obs)
        % pull radiances for observation corresponding to AIRXBCAL atrack
        % and xtrack
        l1cobs(:, k) = L1crad(:, xtracks(j), atracks(j));
        k=k+1;
    end

% end granule number loop
end

% normalize other profile structure fields to remove findex=0 data
% (rtpwrite fails if fields have differing number of columns)
pfields = fieldnames(p);
nzfindex = find(findex ~= 0);
for j = 1 : length(pfields);
    fname = pfields{j};
    eval(sprintf('[m,n] = size(p.%s);', fname));
    if m == 1
        eval(sprintf('p.%s = p.%s(nzfindex);', fname, fname));
    else
        eval(sprintf('p.%s = p.%s(:, nzfindex);', fname, fname));
    end
end

% replace p.robs1 with L1c radiances
p.robs1 = l1cobs;

% Resave as rtp file
outfilepath = fullfile(xbcalpath, ['era_airxbcal_l1c_day' sdoy ...
                    '_clear.rtp']);
rtpwrite(outfilepath, h, ha, p, pa);
