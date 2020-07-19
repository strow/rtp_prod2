lmax = 60000;
dday=01;
for i=182:182
    indir = sprintf('/asl/rtp/rtp_cris_ccast_hires/clear/2019/%03d', ...
                    i);

% $$$     indir=sprintf(['/umbc/xfs2/strow/asl/rtp/rtp_cris2_ccast_hires/' ...
% $$$                'clear/2018/%03d'],i);
    
fprintf(1, '%s\n', indir)
[h,ha,p,pa] = cat_rtp_dir(indir);
p = rtp_sub_prof(p, randperm(length(p.rtime), lmax));
outfile=sprintf('/asl/rtp/rtp_cris_ccast_hires/clear/2019/cris_ecmwf_csarta_clear_d201907%02d.rtp',dday);
fprintf(1, '%s\n', outfile)
rtpwrite(outfile, h,ha,p,pa)
dday = dday + 1;

end