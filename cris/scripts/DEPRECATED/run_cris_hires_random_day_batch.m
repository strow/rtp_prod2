function run_cris_hires_random_day_batch(cfg_file)

addpath ..;    % look one level up for create_* functions
addpath ../util;
addpath /asl/packages/swutils;

cfg=ini2struct(cfg_file);

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));
fprintf(1, '>> Native slurmindex = %d\n', slurmindex);
% $$$ if ~isempty('slurmindex')
% $$$     slurmindex = 0;
% $$$     if isfield(cfg, 'slurmindex')
% $$$         slurmindex = cfg.slurmindex;
% $$$         fprintf(1, '>>> Overriding slurmindex with config -> %d\n', ...
% $$$                 slurmindex);
% $$$     end
% $$$ end

chunk = 1
if isfield(cfg, 'chunk')
    chunk = cfg.chunk;
end
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

    fprintf(1, '>>> Processing day %s\n', infile);
    
    % call the processing function
    [head, hattr, prof, pattr] = create_cris_ccast_hires_random_day_rtp(infile, ...
                                                      cfg);
    % use fnCrisOutput to generate year and doy strings
    % /asl/data/cris/ccast/sdr60_hr/2016/163/SDR_d20160611_t0837285.mat
    % /asl/data/cris/ccast/SDR_j01_s45/2018/005/CrIS_SDR_j01_s45_d20180105_t0006010_g002_v20a.mat
    % for jpss-1 testing
    C = strsplit(infile, '/');
    cris_yearstr = C{6};
    year = int32(str2num(cris_yearstr));
    cris_doystr = C{7};
    doy = int32(str2num(cris_doystr));
    % Make directory if needed
    % cris hires data will be stored in
    % /asl/rtp/rtp_cris_ccast_hires/{clear,dcc,site,random}/<year>/<doy>
    %
    asType = {'random'};
    for i = 1:length(asType)
        % check for existence of output path and create it if necessary. This may become a source
        % for filesystem collisions once we are running under slurm.
        sPath = fullfile(cfg.outputdir,char(asType(i)),cris_yearstr);
        if exist(sPath) == 0
            fprintf(1, '>>> Path %s does not exist. Creating.\n', sPath);
            mkdir(sPath);
        end
        
        % Now save the four types of cris files
        fprintf(1, '>>> writing output rtp file... \n');
        dt = int32(yyyymmdd(datetime(year,01,01) + caldays(doy-1)));
        % output naming convention:
        % <inst>_<model>_<rta>_<filter>_<date>.rtp
        fname = sprintf('%s_%s_%s_%s_d%8d.rtp', cfg.inst, cfg.model, cfg.rta, asType{i}, ...
                        dt);
        rtp_outname = fullfile(sPath, fname);
        fprintf(1, '>>>> Output to: %s\n', rtp_outname);
        rtpwrite(rtp_outname,head,hattr,prof,pattr);
        fprintf(1, 'Done\n');
    end



end
