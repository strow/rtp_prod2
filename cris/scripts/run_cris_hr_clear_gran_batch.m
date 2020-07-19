function run_cris_hr_clear_gran_batch(cfg)

addpath ..;  % look one level up for create_* functions

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

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
    [head, hattr, prof, pattr] = create_cris_ccast_hires_clear_gran_rtp(infile, cfg);

        % use fnCrisOutput to generate year and doy strings
    % /asl/data/cris/ccast/sdr60_hr/2016/163/SDR_d20160611_t0837285.mat
    % /asl/data/cris/ccast/test1/2017/091    %% for jpss-1 testing
    % /asl/cris/ccast/sdr45_npp_HR/2019/177/CrIS_SDR_npp_s45_d20190626_t2342080_g238_v20a.mat
    [gpath, gname, ext] = fileparts(infile);
    C = strsplit(gpath, '/');
    cris_yearstr = C{9};
    cris_doystr = C{10};
    % Make directory if needed
    % cris hires data will be stored in
    % /asl/rtp/rtp_cris_ccast_hires/{clear,dcc,site,random}/<year>/<doy>
    %
    asType = {'clear'};
    for i = 1:length(asType)
        % check for existence of output path and create it if necessary. This may become a source
        % for filesystem collisions once we are running under slurm.
        sPath = fullfile(cfg.outputdir,char(asType(i)),cris_yearstr,cris_doystr);
        if exist(sPath) == 0
            mkdir(sPath);
        end
        
        % Now save the four types of cris files
        fprintf(1, '>>> writing output rtp file... ');
        C = strsplit(gname, '_');
        % output naming convention:
        % <inst>_<model>_<rta>_<filter>_<date>_<time>.rtp
        % /asl/cris/ccast/sdr45_npp_HR/2019/177/CrIS_SDR_npp_s45_d20190626_t2342080_g238_v20a.mat
% $$$         fname = sprintf('%s_%s_%s_%s_%s_%s.rtp', cfg.inst, cfg.model, cfg.rta, asType{i}, ...
% $$$                         C{2}, C{3});
        fname = sprintf('%s_%s_%s_%s_%s_%s.rtp', cfg.inst, cfg.model, cfg.rta, asType{i}, ...
                        C{5}, C{6});  % changed for cris2 cal testing
        rtp_outname = fullfile(sPath, fname);
        rtpwrite(rtp_outname,head,hattr,prof,pattr);
        fprintf(1, 'Done\n');
    end

end    
