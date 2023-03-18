function [head,hattr,prof,pattr] = sdr42rtp(files, i, cfg)

    % variable i is from the external loop counter which is populated
    % with values following the loop stride (i.e. 1, 16, 31,
    % ...). This can index straight into the files array to get the
    % block of files that should be processed in this invocation

    %*************************************************
    % Read in day of granules and concatenate to single rtp structure set
    head=struct;hattr={};prof=struct;pattr={};  % initialize output
                                                % vars empty so there
                                                % is something to
                                                % return even in event
                                                % of failure

    FIRSTGRAN=true;
    for j = i:i+14
        infile = fullfile(files(j).folder, files(j).name);
        [h,ha,p,pa ] = sdr2rtp(infile, cfg);
        if FIRSTGRAN
            head=h;
            hattr=ha;
            prof=p;
            pattr=pa;
            FIRSTGRAN=false;
        else
            % fix p.atrack so we don't duplicate
            p.atrack = p.atrack+(4*(j-1));
            [head,prof] = cat_rtp(head,prof,h,p);
        end
        
    end
    
end

