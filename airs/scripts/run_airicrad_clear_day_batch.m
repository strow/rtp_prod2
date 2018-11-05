function run_airicrad_clear_day_batch(cfg)

% read day file path from specified file list, pass to create_*_rtp
% function and write resulting rtp data to <cfg.outputpath>/year/doy

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

% offset slurmindex to bypass MaxArraySize boundary
%slurmindex = slurmindex + 19999

chunk = cfg.chunk;
for i = 1:chunk
    dayindex = (slurmindex*chunk) + i;
    fprintf(1, '>>> chunk %d  dayindex %d\n', i, dayindex);
    
    % File ~/cris-files-process.txt is a list of filepaths to the input
    % files or this processing. For the initial runs, this was
    % generated by a call to 'ls' while sitting in the directory
    % /asl/data/cris/ccast/sdr60_hr/2015: 
    %    ls -d1 $PWD/{048,049,050}/*.mat >> ~/cris-files-process.txt
    %
    % cris-files-process.txt, then, contains lines like:
    %    /asl/data/cris/ccast/sdr60_hr/2015/048/SDR_d20150217_t1126169.mat
    [status, infile] = system(sprintf('sed -n "%dp" %s | tr -d "\n"', ...
                                      dayindex, cfg.file_list));

    if strcmp(infile, '')
        break;
    end

    % call the processing function
    [head, hattr, prof, pattr] = create_airicrad_clear_day_rtp(infile, ...
                                                      cfg);
    % for jpss-1 testing
    C = strsplit(infile, '/');
    airs_yearstr = C{6};
    airs_doystr = C{7};
    % Make directory if needed
    % cris hires data will be stored in
    % /asl/rtp/rtp_cris_ccast_hires/{clear,dcc,site,random}/<year>/<doy>
    %
    asType = {'clear'};
    for i = 1:length(asType)
        % check for existence of output path and create it if necessary. This may become a source
        % for filesystem collisions once we are running under slurm.
        sPath = fullfile(cfg.outputdir,airs_yearstr, char(asType(i)));
        fprintf(1, '>>> Writing output rtp to directory %s\n', sPath);
        if exist(sPath) == 0
            fprintf(1, '>>>> %s does not exist. Creating\n', sPath);
            mkdir(sPath);
        end
        
        % Now save the four types of cris files
        fprintf(1, '>>> writing output rtp file... ');
        MAXOBS = 60000;
        if length(prof.rtime) > MAXOBS
            prof = rtp_sub_prof(prof, randperm(length(prof.rtime), ...
                                               MAXOBS));
        end
        % output naming convention:
        % <inst>_<model>_<rta>_<filter>_<date>_<time>.rtp
        fname = sprintf('%s_airicrad_day%s_%s.rtp', cfg.model, airs_doystr, asType{i});
        fprintf(1, '%s\n', fname);
        rtp_outname = fullfile(sPath, fname);
        rtpwrite(rtp_outname,head,hattr,prof,pattr);
        fprintf(1, 'Done\n');
    end



end
