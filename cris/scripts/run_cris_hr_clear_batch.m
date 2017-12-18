function run_cris_hr_clear_batch()

addpath ..;  % look one level up for create_* functions

cris_ccast_file_list = '~/cris-hires-files-to-process-test2';

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));


% build config struct
cfg.model = 'era';
cfg.sarta_exec = '/asl/bin/crisg4_oct16';
cfg.rta = 'csarta';
cfg.outputdir = '/asl/rtp/rtp_cris_ccast_hires_test2';
cfg.inst = 'cris';

chunk = 1;
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
                                      dayindex, cris_ccast_file_list));

    if strcmp(infile, '')
        break;
    end

    % call the processing function
    [head, hattr, prof, pattr] = create_cris_ccast_hires_gran_clear_rtp(infile, cfg);

        % use fnCrisOutput to generate year and doy strings
    % /asl/data/cris/ccast/sdr60_hr/2016/163/SDR_d20160611_t0837285.mat
    % /asl/data/cris/ccast/test1/2017/091    %% for jpss-1 testing
    [gpath, gname, ext] = fileparts(infile);
    C = strsplit(gpath, '/');
    cris_yearstr = C{7};
    cris_doystr = C{8};
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
        fname = sprintf('%s_%s_%s_%s_%s_%s.rtp', cfg.inst, cfg.model, cfg.rta, asType{i}, ...
                        C{2}, C{3});
        rtp_outname = fullfile(sPath, fname);
        rtpwrite(rtp_outname,head,hattr,prof,pattr);
        fprintf(1, 'Done\n');
    end

end    
