function run_cris_ccast_hires_allfov_batch(cfg)

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
    [head, hattr, prof, pattr] = create_cris_ccast_hires_allfov_rtp(infile, cfg);
    if isempty(prof)
        fprintf(2, '>>> No obs found in granule %d.\n', i);
        exit
    end

    % use fnCrisOutput to generate year and doy strings
    %/asl/data/UW_CrIS_PL/h5_SDR_J01_FSR_PLon/2019/002/SCRIF_j01_d20190102_t2357039_e2357337_b05826_c20190205014148823988_ADu_ops_gz.h5
    %/asl/data/cris/ccast/sdr60_hr/2016/163/SDR_d20160611_t0837285.mat
    %/asl/data/cris/ccast/test1/2017/091 %% for jpss-1 testing
    %/asl/s1/strow/cris_sdr04/2021-05-21/SCRIF/SCRIF_npp_d20210521_t2345439_e2346137_b49565_c20210524164654344018_ADu_ops.h5
    [gpath, gname, ext] = fileparts(infile);
    C = strsplit(gpath, '/');
    cris_yearstr = C{6};
    cris_daystr = C{7};
    C = strsplit(gname, '_');

    % Make directory if needed
    % cris hires data will be stored in
    % /asl/rtp/rtp_cris_ccast_hires/{clear,dcc,site,random}/<year>/<doy>
    %
    asType = {'allfov'};
    for i = 1:length(asType)
        % check for existence of output path and create it if necessary. This may become a source
        % for filesystem collisions once we are running under slurm.
        sPath = fullfile(cfg.outputdir,char(asType(i)),cris_yearstr,cris_daystr);
        if exist(sPath) == 0
            mkdir(sPath);
        end
        
        % Now save the four types of cris files
        fprintf(1, '>>> writing output rtp file... ');
        % output naming convention:
        % <inst>_<model>_<rta>_<filter>_<date>_<time>.rtp
        % cris_sdr_ecmwf_csarta_allfov_npp_s45_d20210329.rtp
        fname = sprintf('%s_%s_%s_%s_%s_%s_%s.rtp', cfg.inst, cfg.model_cfg.model, cfg.rta_cfg.rta, asType{i}, ...
                        C{5}, C{6}, C{7});
        rtp_outname = fullfile(sPath, fname);
        fprintf(1, '>> Writing output to file: %s\n', rtp_outname);
        rtpwrite(rtp_outname,head,hattr,prof,pattr);
        fprintf(1, 'Done\n');
    end

end    