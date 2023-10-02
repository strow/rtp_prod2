function rtp_run_klayers(opts)

    excommand = sprintf('%s fin=%s fout=%s > %s/klayers_stdout',
                        opts.klayers_exec,
                        opts.klayers_in,
                        opts.klayers_out,
                        opts.sTempPath);
    unix(excommand)

end
