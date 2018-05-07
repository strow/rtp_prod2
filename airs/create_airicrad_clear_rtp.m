function create_airicrad_clear_rtp(inpath, outfile_head, cfg)
%
% NAME
%   create_airicrad_rtp -- wrapper to process AIRICRAD to RTP
%
% SYNOPSIS
%   create_airicrad_rtp(infile, outfile_head)
%
% INPUTS
%    infile :   path to input AIRICRAD hdf file
%    outfile_head  : path to output rtp file (minus extension)
%
% L. Strow, Jan. 14, 2015
%
% DISCUSSION (TBD)
func_name = 'create_airicrad_clear_rtp';

klayers_exec = '/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
sarta_exec   = '/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';

addpath('/home/sbuczko1/git/swutils');
trace.githash = githash(func_name);
trace.RunDate = char(datetime('now','TimeZone','local','Format', ...
                              'd-MMM-y HH:mm:ss Z'));
fprintf(1, '>>> Run executed %s with git hash %s\n', ...
        trace.RunDate, trace.githash);

% Execute user-defined paths
addpath '/home/sbuczko1/git/rtp_prod2/util'
addpath '/home/sbuczko1/git/rtp_prod2/airs'
addpath '/home/sbuczko1/git/rtp_prod2/airs/readers'
addpath('/asl/matlib/rtptools');   % for cat_rtp

% build output filename
% assumes path is like: /asl/data/airs/AIRICRAD/<year>/<doy>
C = strsplit(inpath, '/');
sYear = C{6};
sDoy = C{7};
outfile_base = fullfile(outfile_head, sYear, 'clear');
if exist(outfile_base) == 0
    status = mkdir(outfile_base);
end
outfile_path = fullfile(outfile_base, ...
                        sprintf('%s_airicrad2_day%s_clear.rtp', ...
                                cfg.model, sDoy));

load /home/sbuczko1/git/rtp_prod2/airs/util/sarta_chans_for_l1c.mat

% This version operates on a day of AIRICRAD granules and
% concatenates the subset of clear obs into a single output file
% >> inpath is the path to an AIRS day of data
% /asl/data/airs/AIRICRAD/<year>/<doy>
files = dir(fullfile(inpath, '*.hdf'));
dbtun_ag = [];

for i=1:length(files)
    % Read the AIRICRAD file
    infile = fullfile(inpath, files(i).name);
    fprintf(1, '>>> Reading input file: %s   ', infile);
    try
        [eq_x_tai, freq, p, pattr] = read_airicrad(infile);
    catch
        fprintf(2, ['>>> ERROR: failure in read_airicrad for granule %s. ' ...
                    'Skipping.\n'], infile);
        continue;
    end
    fprintf(1, 'Done. \n')
    
    if i == 1 % only need to build the head structure once but, we do
              % need freq data read in from first data file
              % Header 
        head = struct;
        head.pfields = 4;  % robs1, no calcs in file
        head.ptype = 0;    
        head.ngas = 0;
        
        % Assign header attribute strings
        hattr={ {'header' 'pltfid' 'Aqua'}, ...
                {'header' 'instid' 'AIRS'}, ...
                {'header' 'githash' trace.githash}, ...
                {'header' 'rundate' trace.RunDate}, ...
                {'header' 'klayers_exec' klayers_exec}, ...
                {'header' 'sarta_exec' sarta_exec} };
        
        nchan = size(p.robs1,1);
        %vchan = aux.nominal_freq(:);
        vchan = freq;
        
        % Assign header variables
        head.instid = 800; % AIRS 
        head.pltfid = -9999;
        head.nchan = length(ichan);
        head.ichan = ichan;
        head.vchan = vchan;
        head.vcmax = max(head.vchan);
        head.vcmin = min(head.vchan);
        fprintf(1, '>> Header struct built\n');
    end  % end if i == 1

        % run airs_find_uniform and check for any obs that pass
        % looser land criteria. If such exist, subset to them and
        % continue on to airs_find_clear. If such do not exist,
        % there is no point in running any of the following, so
        % jump to the next granule
        [dbtun, mbt] = airs_find_uniform(head, p);
        iuniform = find(abs(dbtun) < 1.0);
        nuniform = length(iuniform);
        if nuniform > 0
            % subset down to just the uniform pixels
            fprintf(1, '>> Uniformity test: %d accepted\n', nuniform);
            p = rtp_sub_prof(p, iuniform);
            dbtun_ag = [dbtun_ag dbtun(iuniform)];
            
            % concatenate rtp structs
            if ~exist('prof')
                prof = p;
            else
                [head, prof] = cat_rtp(head, prof, head, p);
            end
        else
            continue
        end
            
end  % end for i=1:length(files)
    fprintf(1, '>>>> Total of %d obs passed uniformity\n', length(prof.rtime));
    
    % Fix for zobs altitude units
    if isfield(p,'zobs')
        iz = prof.zobs < 20000 & prof.zobs > 20;
        prof.zobs(iz) = prof.zobs(iz) * 1000;
    end

    % Add in model data
    fprintf(1, '>>> Add model: %s...', cfg.model)
    switch cfg.model
      case 'ecmwf'
        [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
      case 'era'
        [prof,head,pattr]  = fill_era(prof,head,pattr);
      case 'merra'
        [prof,head,pattr]  = fill_merra(prof,head,pattr);
    end
    head.pfields = 5;
    fprintf(1, 'Done\n');

    % Dan Zhou's one-year climatology for land surface emissivity and
    % standard routine for sea surface emissivity
    fprintf(1, '>>> Running rtp_add_emis...');
    try
        [prof,pattr] = rtp_add_emis(prof,pattr);
    catch
        fprintf(2, '>>> ERROR: rtp_add_emis failure for %s/%s\n', sYear, ...
                sDoy);
        return;
    end

    % Save the rtp file
    fprintf(1, '>>> Saving first rtp file... ');
    [sID, sTempPath] = genscratchpath();

    fn_rtp1 = fullfile(sTempPath, ['airs_' sID '_1.rtp']);
    rtpwrite(fn_rtp1,head,hattr,prof,pattr)
    fprintf(1, 'Done\n');

    % run klayers
    fprintf(1, '>>> running klayers... ');
    fn_rtp2 = fullfile(sTempPath, ['airs_' sID '_2.rtp']);
    klayers_run = [klayers_exec ' fin=' fn_rtp1 ' fout=' fn_rtp2 ' > ' ...
                   sTempPath '/kout.txt'];
    unix(klayers_run);
    fprintf(1, 'Done\n');

    % Run sarta
    fprintf(1, '>>> Running sarta... ');
    fn_rtp3 = fullfile(sTempPath, [sID '_3.rtp']);
    sarta_run = [sarta_exec ' fin=' fn_rtp2 ' fout=' fn_rtp3 ...
                 ' > ' sTempPath '/sartaout.txt'];
    unix(sarta_run);
    fprintf(1, 'Done\n');

    % Read in new rcalcs and insert into origin prof field
    stFileInfo = dir(fn_rtp3);
    fprintf(1, ['*************\n>>> Reading fn_rtp3:\n\tName:\t%s\n\tSize ' ...
                '(GB):\t%f\n*************\n'], stFileInfo.name, stFileInfo.bytes/1.0e9);
    [~,~,p2,~] = rtpread(fn_rtp3);
    prof.rclr = p2.rcalc;
    clear p2;
    head.pfields = 7;

    % temporary files are no longer needed. delete them to make sure we
    % don't fill up the scratch drive.
    delete(fn_rtp1, fn_rtp2, fn_rtp3);
    fprintf(1, 'Done\n');

    % we have obs that passed uniformity and now have calcs
    % associated so we can do a clear test
    disp('running airs_find_clear')
    nobs = length(prof.rtime);
    [iflagsc, bto1232, btc1232] = airs_find_clear(head, prof, 1:nobs);
    
    iclear_sea    = find(iflagsc == 1 & abs(dbtun_ag) < 0.5 & prof.landfrac <= 0.01);
    iclear_notsea = find(iflagsc == 1 & abs(dbtun_ag) < 1.0 & prof.landfrac >  0.01);
    iclear = union(iclear_sea, iclear_notsea);
    nclear = length(iclear);
    fprintf(1, '>>>> Total of %d uniform obs passed clear test\n', nclear);
    prof = rtp_sub_prof(prof, iclear);
   
    % profile attribute changes for airicrad
    pa = set_attr('profiles', 'robs1', infile);
    pa = set_attr(pa, 'rtime', 'TAI:1958');

    % Now save the output random rtp file
    fprintf(1, '>>> writing output rtp files... ');

    rtpwrite(outfile_path, head, hattr, prof, pa);
    fprintf(1, 'Done\n');

    
