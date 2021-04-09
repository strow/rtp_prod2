function test_rtp(rtpfile)

% requires rtpread and rad2bt in the path

[h,ha,p,pa] = rtpread(rtpfile);

figure

% convert robs1, rclr, and rcld to bt (does not assume all are
% present)
if isfield(p,'robs1')
    bt = real(rad2bt(h.vchan, p.robs1));
    plot(h.vchan, mean(bt,2))
    hold on
end

if isfield(p,'rclr')
    btc = real(rad2bt(h.vchan, p.rclr));
    plot(h.vchan, mean(btc,2))
    hold on
end

if isfield(p,'rcld')
    btcc = real(rad2bt(h.vchan, p.rcld));
    plot(h.vchan, mean(btcc,2))
    hold on
end


    