function run_test_driver_sarta_cloud()
    rtp_addpaths  % rtpread/write
    addpath ~/git/matlib/clouds/sarta  % driver_sarta_cloud_rtp

    % ************************************************
    % EDIT FOR TEST
    CUMSUM = [-1,9999];       % -1, 9999
    OPATH = {'CSm1b', 'CS9999b'};  % CS{m1,9999}[ab]  a=ebb636, b=0ebf7c
                       % (matlib commit)
    DAYSTART = 200;
    % *********************************************

    % grab the slurm array index for this process
    slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));
% $$$     if exist(slurmindex) == 0  % testing outside sbatch control
% $$$         slurmindex = 0;
% $$$     end

    % run these 16 days
    doy = DAYSTART + slurmindex;

    % Build rtp filename
    rtppath = '/asl/rtp/rtp_airicrad_v6/2005/random_fs';
    rtpname = sprintf('era_airicrad_day%03d_random_fs.rtp', doy);
    rtpfile = fullfile(rtppath, rtpname);

    % loop over cumsum possibilities
    for i = 1:length(OPATH)
        % output modified rtp file to new directory tree (make tree, if
        % necessary)
        output_rtppath = sprintf('%s_%s', rtppath, OPATH{i});
        if exist(output_rtppath) == 0
            mkdir(output_rtppath);
        end
        output_rtp = fullfile(output_rtppath, rtpname);
        
        % ********************************************
        fprintf(1, '**********************************\n')
        fprintf(1, 'modifying file %s\n', rtpfile)
        fprintf(1, 'CUMSUM = %d\n', CUMSUM(i))
        fprintf(1, 'output to %s\n', output_rtp)
        fprintf(1, '**********************************\n')
        % ********************************************
        
        % read rtp file
        [head, hattr, prof, pattr] = rtpread(rtpfile);
        
        % read in existing rtp and run through driver_sarta_cloud
        run_sarta.cloud = 1;
        run_sarta.clear = -1;  % skip running clear sarta. use
                               % existing
        run_sarta.ForceNewSlabs = 1;
        run_sarta.cumsum = CUMSUM(i);
        
        [prof0, oslabs] = driver_sarta_cloud_rtp(head, hattr, prof, pattr, ...
                                                 run_sarta);
        
        % write out revised rtp file
        rtpwrite(output_rtp, head, hattr, prof0, pattr)

    end
    
    % done