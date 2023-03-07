function run_sarta(opts)

    % if opts.runclear run clear sarta
    run_sarta_clear(opts)

    % if opts.runcloudy run cloudy sarta

    
    
end


function run_sarta_clear(opts)

    
% execute sarta
    excommand = sprintf('%s fin=%s fout=%s > %s/klayers_stdout',
                        opts.sartaclr_exec,
                        opts.sarta_in,
                        opts.sarta_out,
                        opts.sTempPath);
    unix(excommand)

end


function run_sarta_cloudy(opts)
%
% set up slabs and other cloudy sarta ancillary data
    

% execute sarta
    excommand = sprintf('%s fin=%s fout=%s > %s/klayers_stdout',
                        opts.sartacld_exec,
                        opts.sarta_in,
                        opts.sarta_out,
                        opts.sTempPath);
    unix(excommand)




end

    
    
