lmax = 60000;
dday=8;
for i=67:77
indir=sprintf(['/umbc/xfs2/strow/asl/rtp/rtp_cris2_ccast_hires/' ...
               'clear/2018/%03d'],i);
fprintf(1, '%s\n', indir)
[h,ha,p,pa] = cat_rtp_dir(indir);
p = rtp_sub_prof(p, randperm(length(p.rtime), lmax));
outfile=sprintf('cris_ecmwf_isarta_clear_d201803%02d.rtp',dday);
fprintf(1, '%s\n', outfile)
rtpwrite(outfile, h,ha,p,pa)
dday = dday + 1;

end