function run_cris_batch()
set_process_dirs;
addpath(rtp_sw_dir);
cris_ccast_file_list = '~/cris-hires-files-to-process';

% grab the slurm array index for this process
slurmindex = str2num(getenv('SLURM_ARRAY_TASK_ID'));

% offset slurmindex to bypass MaxArraySize boundary
%slurmindex = slurmindex + 19999

chunk = 3;
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
    
    % separate out parts of file path. We want to keep the bulk of the
    % filename intact but change SDR -> rtp and change the extension to
    % rtp as well as we make the output file path
    [path, name, ext] = fileparts(infile);

    outfile = strrep(name, 'SDR', 'rtp');

    % call the processing function
    create_cris_ccast_hires_rtp(infile, outfile)

end