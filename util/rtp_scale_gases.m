function rtp_scale_gases(opts)
%
% see http://asl.umbc.edu/pub/packages/rtpspec201.html for gas list
    
    % read in klayers output
    [h,ha,p,pa] = rtpread(opts.rtpfile);
    delete opts.rtpfile

    % scale CO2
    if isfield(opts, 'scaleco2')
        p.gas_2 = p.gas_2 * opts.scaleco2;
        pattr{end+1} = {'p_granules' 'scaleCO2' sprintf('%f', opts.scaleco2)};
    end

    % scale CH4
    if isfield(opts, 'scalech4')
        p.gas_6 = p.gas_6 * opts.scalech4;
        pattr{end+1} = {'p_granules' 'scaleCH4' sprintf('%f', opts.scalech4)};        
    end

    % scale NO2
    if isfield(opts, 'scaleno2')
        p.gas_10 = p.gas_10 * opts.scaleno2;
        pattr{end+1} = {'p_granules' 'scaleNO2' sprintf('%f', opts.scaleno2)};        
    end

    % write out rtp file with scaled gas concentrations
    rtpwrite(opts.rtpfile,h,ha,p,pa)
   

end
