function psarta_run(fn_rtp_in, fn_rtp_out, sartapath)
% Run sarta in parallel by breaking input file into 8 pieces and
% spawning 8 successive background jobs via the shell

[sNodeID, sScratchPath] = genscratchpath();

% read in rtp input file
[head,hattr,prof,pattr] = rtpread(fn_rtp_in);

nobs = length(prof.robs1);
iobsblocksz = ceil(nobs/8);
fprintf(1, '>>> Splitting sarta input file: ');
i=0;
for iobsidx = [1:iobsblocksz:nobs]
    i=i+1;
    fprintf(1, '%d ', i);
    iobsblock = [iobsidx:min(iobsidx+(iobsblocksz-1), nobs)];
    rtp_sub = rtp_sub_prof(prof, iobsblock);
    % write out intermediate rtp file
    fn_rtp = fullfile(sScratchPath, sprintf('psarta_%s_%d_in.rtp', ...
                                            sNodeID, i));
    rtpwrite(fn_rtp,head,hattr,rtp_sub,pattr)
    
end
fprintf(1, '\n');

% call sarta shell script to kick off processing
fprintf(1, '>>> Running run_psarta.sh\n');
psartapath='~/git/rtp_prod2/airs';
[status, cmdout] = system(sprintf('%s/%s %s %s %s', psartapath, ...
                                  'run_psarta.sh', sScratchPath, ...
                                  sNodeID, sartapath));

% *** concatenate 'N' sarta output files into a single rtp file
% once again
fprintf(1, '>>> Concatenating psarta output files\n');
[h, ha, p, pa] = rtp_cat_prof(sScratchPath, sNodeID);

% write out output rtp file
fprintf(1, '>>> Writing full psarta output file\n');
fn_rtp_out
rtpwrite(fn_rtp_out, h, ha, p, pa);

% delete intermediate rtp files
fprintf(1, '>>> Deleting temporary files\n');
sRMcmd = sprintf('rm %s/psarta_%s_*_{in,out}.rtp', sScratchPath, sNodeID);
[status, cmdout] = system(sRMcmd);

end
