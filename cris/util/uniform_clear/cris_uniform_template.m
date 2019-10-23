% cris_clear_template.m
%
% Use to find uniform clear CrIS data by converting to an AIRS scan

% Use 1231 channel for uniformity test

% Paths
fnd = '/asl/rtp/rtp_cris_ccast_hires/allfov/2018/005';
% Get directory listing of rtp files
a = dir(fullfile(fnd,'cris*csarta*.rtp'));
% Pick on
fn = fullfile(fnd,a(10).name);

% Prof data in p
[h,ha,p,pa] = rtpread(fn);

% Channel selection and form BT
ch = find( h.vchan > 1231, 1);
bt_rtp = rad2bt(ch,p.robs1(ch,:));

% Get bt list into AIRS form
bt = reshape(bt_rtp,9,30,45);
btscan = create_airs_scan_from_cris(bt)';

% Find clear based on this channel and this threshold
threshold = 0.2;
cl = scan2d_clear(btscan,threshold);

% Get cl indices that are clear
k = ~isnan(cl);

% Need to map k back to rtp linear indices (do this only once in real code)
ind = reshape(1:(9*30*45),9,30,45);
indscan = create_airs_scan_from_cris(ind)';

% Find rtp clear indices
cl_ind = indscan(k);

% Plot some results

% Clear indices in scan geometry
k = ~isnan(cl);

figure;
imagesc(btscan);colorbar;
figure;
btscan_cl = btscan;
btscan_cl(k) = min(btscan(:))-10;
imagesc(btscan_cl);colorbar

% Plot results using rtp indexing
figure;
scatter(p.rlon,p.rlat,30,bt_rtp,'filled');
hold on;
plot(p.rlon(cl_ind),p.rlat(cl_ind),'o');
xl = xlim;yl = ylim;
c = load('coast');
plot(c.long,c.lat,'k-');
ylim(yl);xlim(xl);
