lmax = 60000;
dday=04;
for i=338:342
    indir = sprintf('/asl/rtp/cris/npp_dec6/clear/2021/%03d', ...
                    i);

% $$$     indir=sprintf(['/umbc/xfs2/strow/asl/rtp/rtp_cris2_ccast_hires/' ...
% $$$                'clear/2018/%03d'],i);
    
fprintf(1, '%s\n', indir)
[h,ha,p,pa] = cat_rtp_dir(indir);
if length(p.rtime) > lmax
    p = rtp_sub_prof(p, randperm(length(p.rtime), lmax));
end
outfile=sprintf('/asl/rtp/cris/npp_dec6/clear/2021/cris_sdr_ecmwf_csarta_clear_d202112%02d.rtp',dday);
fprintf(1, '%s\n', outfile)
rtpwrite(outfile, h,ha,p,pa)
dday = dday + 1;

end