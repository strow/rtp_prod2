function [head,hattr,prof,pattr] = read_airs(inpath, cfg)

    mfilepath = mfilename('fullpath');
    mp = fileparts(mfilepath);

    %*************************************************
    % Read the AIRICRAD file *************************
    fprintf(1, '>>> Reading %s input file: %s   ', cfg.airstype, inpath);
    switch cfg.airstype
      case 'airicrad'
        [eq_x_tai, freq, prof, pattr] = read_airicrad(inpath);
      otherwise
        error("AIRS data source %s not implemented", cfg.airstype);
    end
    fprintf(1, 'Done\n');
    %*************************************************

    %*************************************************
    % Build out rtp structs **************************
    nchan = size(prof.robs1,1);
% $$$ chani = (1:nchan)'; % need to change to reflect proper sarta ichans
% $$$                     % for chan 2378 and higher
% following line loads array 'ichan' which gets swapped for chani below
    load(fullfile(mp, '../static/sarta_chans_for_l1c.mat'));

    %vchan = aux.nominal_freq(:);
    vchan = freq;

    % Header 
    head = struct;
    head.pfields = 4;  % robs1, no calcs in file
    head.ptype = 0;    % levels
    head.ngas = 0;
    head.instid = 800; % AIRS 
    head.pltfid = -9999;
    head.nchan = length(ichan); % was chani
    head.ichan = ichan;  % was chani
    head.vchan = vchan; % was vchan(chani)
    head.vcmax = max(head.vchan);
    head.vcmin = min(head.vchan);

    % hattr
    hattr={ {'header' 'pltfid' 'Aqua'}, ...
            {'header' 'instid' 'AIRS'}
            {'header' 'githash' trace.githash}, ...
            {'header' 'rundate' trace.RunDate} };

    % profile attribute changes for airicrad
    pattr = set_attr(pattr, 'robs1', inpath);
    pattr = set_attr(pattr, 'rtime', 'TAI:1958');

    %*************************************************
end


function [eq_x_tai, f, gdata, attr, opt] = read_airicrad(fn);
%
% Reads an AIRS level 1c granule file and returns an RTP-like structure of
% observation data.  Returns all 2645 channels and 90x135 FOVs.
%
% Input:
%    fn = (string) Name of an AIRS l1b granule file, something like
%          'AIRS.2016.12.10.229.L1C.AIRS_Rad.v6.1.2.0.G16346151726.hdf'
%
% Output:
%    eq_x_tai = (1x 1) 1993 TAI time of southward equator crossing
%    f  = (nchan x 1) channel frequencies
%    gdata = (structure) RTP "prof" like structure
%    attr = (cell of strings) attribute strings
%
% Note: if the granule contains no good data, the output variables
% are returned empty.
%
% L1C data is cleaned. Calnum based channel assessment as is done
% in L1B is unnecessary here as it is done in the raw data. Data
% that might have been rejected in L1B is filled with interpolated
% values. Channels which have been filled (and the reasons for that
% filling) can be tracked through L1CSynthReason (gdata.l1csreason)).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% establish local directory structure
    currentFilePath = mfilename('fullpath');
    [cfpath, cfname, cfext] = fileparts(currentFilePath);
% $$$ fprintf(2, '>> Using file: %s\n', currentFilePath);

    % Granule dimensions
    nchan=2645;
    nxtrack=90;
    natrack=135;
    nobs=nxtrack*natrack;

    % Default f
% $$$ load /asl/matlab2012/airs/readers/f_default_l1c.mat
    load(fullfile(cfpath, '../static/f_default_l1c.mat'))
    f_default = f;

    % Read "state" and find good FOVs
    junk = hdfread(fn, 'state');
    state = reshape( double(junk'), 1,nobs);
    i0=find( state == 0);  % Indices of "good" FOVs
    n0=length(i0);
    %

    % Read latitude
    junk = hdfread(fn, 'Latitude');
    rlat = reshape( double(junk'), 1,nobs);
    ii=find( rlat > -90.01);  % Indices of "good" FOVs
    i0=intersect(i0,ii);
    n0=length(i0);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (n0 > 0)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Read the date/time fields
        junk = cell2mat(hdfread(fn, 'start_Time'));
        start_Time = double(junk(1));
        %
        junk = cell2mat(hdfread(fn, 'end_Time'));
        end_Time = double(junk(1));
        %
        junk = cell2mat(hdfread(fn, 'granule_number'));
        granule_number = double(junk(1));
        %
        junk = cell2mat(hdfread(fn, 'eq_x_tai'));
        eq_x_tai = double(junk(1));


        % Compute granule mean TAI
        meantai = 0.5*(start_Time + end_Time);
        clear start_Time end_Time

        % Read per scanline fields; expand to per FOV later
        %
        % satheight (1 x natrack)
        junk = cell2mat(hdfread(fn, 'satheight'));
        satheight = double(junk'); %'

        % Read in the channel freqs
        junk = cell2mat(hdfread(fn, 'nominal_freq'));
        nominal_freq = double(junk);
        if (max(f) < -998)
            disp('WARNING! L1C file contains bad nominal_freq; using default')
            nominal_freq = f_default;
        end

        % Declare temporary variables for expansion
        tmp_atrack = zeros(1,nobs);
        tmp_xtrack = zeros(1,nobs);
        tmp_zobs   = zeros(1,nobs);

        % Loop over along-track and fill in temporary variables
        ix=1:nxtrack;
        for ia=1:natrack
            iobs=nxtrack*(ia-1) + ix;
            %
            % Fill in cross-track
            tmp_atrack(iobs)=ia;
            tmp_xtrack(iobs)=ix;
            tmp_zobs(iobs)=satheight(ia)*1000;  % convert km to meters
        end
        %
        clear ix ia iobs satheight


        % Subset temporary variables for state and re-assign to gdata
        gdata.findex = granule_number*ones(1,n0);
        gdata.atrack = tmp_atrack(i0);
        gdata.xtrack = tmp_xtrack(i0);
        gdata.zobs   = tmp_zobs(i0);
        %
        clear tmp_atrack tmp_xtrack tmp_zobs

        % *** native reads with hdfread are atrack x xtrack (135 x 90) ***
        % *** must transpose before reshaping to 1-D array             ***

        % Read in observed radiance, reshape, and subset for state.
        % Note: this is a very large array!
        % observed radiance is stored as (nxtrack x natrack x nchan)
        junk = permute(hdfread(fn, 'radiances'), [3 2 1]);
        % reshape but do not convert to double yet
        junk2 = reshape(junk, nchan,nobs);
        clear junk
        % subset and convert to double
        gdata.robs1=double( junk2(:,i0) );
        clear junk2


        % Read the per FOV data
        gdata.rlat = rlat(i0);
        clear rlat
        %
        junk = hdfread(fn, 'Longitude');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.rlon = junk2(i0);
        %
        junk = hdfread(fn, 'Time');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.rtime = airs2tai(junk2(i0));
        %
        junk = hdfread(fn, 'scanang');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.scanang = junk2(i0);
        %
        junk = hdfread(fn, 'satzen');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.satzen = junk2(i0);
        %
        junk = hdfread(fn, 'satazi');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.satazi = junk2(i0);
        %
        junk = hdfread(fn, 'solzen');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.solzen = junk2(i0);
        %
        junk = hdfread(fn, 'solazi');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.solazi = junk2(i0);
        %
        junk = hdfread(fn, 'topog');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.salti =junk2(i0);
        %
        junk = hdfread(fn, 'landFrac');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.landfrac = junk2(i0);
        %
        junk = permute(hdfread(fn, 'L1cProc'), [3 2 1]);
        junk2 = reshape( double(junk), nchan, nobs);
        gdata.l1cproc = junk2(:,i0);
        %
        junk = permute(hdfread(fn, 'L1cSynthReason'), [3 2 1]);
        junk2 = reshape( double(junk), nchan, nobs);
        gdata.l1csreason = junk2(:,i0);
        %
        junk = cell2mat(hdfread(fn,'sat_lat'));
        junk2 = reshape(repmat(junk,90,1), 1, nobs);
        gdata.satlat = junk2(i0);
        %
        junk = cell2mat(hdfread(fn,'sat_lon'));
        junk2 = reshape(repmat(junk,90,1), 1, nobs);
        opt.satlon = junk2(i0);
        %
        % iudefs (maximum of 10?)
        junk = hdfread(fn, 'dust_flag');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.iudef(1,:) = junk2(i0);
        %
        junk = hdfread(fn, 'dust_score');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.iudef(2,:) = junk2(i0);
        %
        junk = hdfread(fn, 'SceneInhomogeneous');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.iudef(3,:) = junk2(i0);
        %
        junk = cell2mat(hdfread(fn, 'scan_node_type'));
        junk2 = reshape( (ones(90,1)*double(junk))', 1,nobs);
        gdata.iudef(4,:) = junk2(i0);
        %
        junk = permute(hdfread(fn, 'AB_Weight'), [3 2 1]);
        junk2 = reshape( double(junk), nchan, nobs);
        opt.ABweight = junk2(:,i0);
        %

        % udefs (maximum of 20?)
        %
        junk = hdfread(fn, 'sun_glint_distance');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.udef(1,:) = junk2(i0);
        %
        junk = hdfread(fn, 'spectral_clear_indicator');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.udef(2,:) = junk2(i0);
        %
        junk = hdfread(fn, 'BT_diff_SO2');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.udef(3,:) = junk2(i0);
        %
        junk = permute(hdfread(fn, 'NeN'), [3 2 1]);
        junk2 = reshape( double(junk), nchan, nobs);
        opt.NeN = junk2(:,i0);
        %
        junk = hdfread(fn, 'Inhomo850');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.udef(4,:) = junk2(i0);
        %
        junk = hdfread(fn, 'Rdiff_swindow');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.udef(5,:) = junk2(i0);
        %
        junk = hdfread(fn, 'Rdiff_lwindow');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.udef(6,:) = junk2(i0);
        %

        clear junk junk2 i0

        % Assign attribute strings
        attr={{'profiles' 'iudef(1,:)' 'Dust flag:[1=true,0=false,-1=land,-2=cloud,-3=bad data]'},...
              {'profiles' 'iudef(2,:)' 'Dust_score:[>380 (probable), N/A if Dust Flag < 0]'},...
              {'profiles' 'iudef(3,:)' 'SceneInhomogeneous:[128=inhomogeneous,64=homogeneous]'},...
              {'profiles' 'iudef(4,:)' 'scan_node_type [0=Ascending, 1=Descending]'},...
              {'profiles' 'udef(1,:)' 'sun_glint_distance:[km to sunglint,-9999=unknown,30000=no glint]'},...
              {'profiles' 'udef(2,:)' 'spectral_clear_indicator:[2=ocean clr,1=ocean n/clr,0=inc. data,-1=land n/clr,-2=land clr]'},...
              {'profiles' 'udef(3,:)' 'BT_diff_SO2:[<-6, likely volcanic input]'},...
              {'profiles' 'udef(4,:)' 'Inhomo850:[abs()>0.84 likely inhomogeneous'},...
              {'profiles' 'udef(5,:)' 'Rdiff_swindow'},...
              {'profiles' 'udef(6,:)' 'Rdiff_lwindow'}};

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        disp('No good FOVs in L1C granule file:')
        disp(fn)

        meantime=[];
        f=[];
        gdata=[];
        attr = [];

    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
%%% end of function %%%

function [eq_x_tai, f, gdata, attr] = read_airibrad(fn);

% function [eq_x_tai, f, gdata, attr] = xreadl1b_all(fn);
%
% Reads an AIRS level 1b granule file and returns an RTP-like structure of
% observation data.  Returns all 2378 channels and 90x135 FOVs.
%
% REQUIRES:
% addpath(genpath('/home/sbuczko1/git/rtp_prod2/'));
%
% Input:
%    fn = (string) Name of an AIRS l1b granule file, something like
%          'AIRS.2000.12.15.084.L1B.AIRS_Rad.v2.2.0.64.A000'
%
% Output:
%    eq_x_tai = (1x 1) 1993 TAI time of southward equator crossing
%    f  = (nchan x 1) channel frequencies
%    gdata = (structure) RTP "prof" like structure
%    attr = (cell of strings) attribute strings
%
% Note: if the granule contains no good data, the output variables
% are returned empty.
%

% Created: 15 January 2003, Scott Hannon - based on readl1b_center.m
% Update: 11 March 2003, Scott Hannon - add check of field "state" so
%    routine only returns FOVs with no known problems.  Also correct
%    mis-assignment of calflag (previously was all wrong).
% Update: 26 March 2003, Scott Hannon - also check latitude ("state" is
%    not entirely reliable).
% Update: 02 Nov 2005, S.Hannon - add default f in case L1B entry is bad
% Update: 14 Jan 2010, S.Hannon - read granule_number and eq_x_tai; change
%    output meantime to eq_x_tai, add findex to gdata
% Update: 13 Oct 2010, S.Hannon - read rtime (previously estimated)
% Update: 16 Nov 2010, S.Hannon - read CalGranSummary & NeN; call
%    data_to_calnum_l1b; read nominal_freq
% Update: 15 Oct 2011, S.Hannon - add path for data_to_calnum_l1b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Granule dimensions
    nchan=2378;
    nxtrack=90;
    natrack=135;
    nobs=nxtrack*natrack;

    % Default f
    load /asl/matlab2012/airs/readers/f_default_l1b.mat
    f_default = f;

    % Open granule file
    file_name = fn;
% $$$ file_id   = hdfsw('open',file_name,'read');
% $$$ swath_id  = hdfsw('attach',file_id,'L1B_AIRS_Science');


    % Read "state" and find good FOVs
% $$$ [junk,s]=hdfsw('readfield',swath_id,'state',[],[],[]);
% $$$ if s == -1; disp('Error reading state');end;
    junk = hdfread(file_name, 'state');
    state = reshape( double(junk'), 1,nobs);
    i0=find( state == 0);  % Indices of "good" FOVs
% $$$ i0=find( state == 1);  % Indices of "good" FOVs (v6 'Special' processing)
    n0=length(i0);
    %
    clear state

    % Read latitude
% $$$ [junk,s]=hdfsw('readfield',swath_id,'Latitude',[],[],[]);
% $$$ if s == -1; disp('Error reading latitude');end;
    junk = hdfread(file_name, 'Latitude');
    rlat = reshape( double(junk'), 1,nobs);
    ii=find( rlat > -90.01);  % Indices of "good" FOVs
    i0=intersect(i0,ii);
    n0=length(i0);

    % Read CalChanSummary
% $$$ [junk,s]=hdfsw('readfield',swath_id,'CalChanSummary',[],[],[]);
% $$$ if s == -1; disp('Error reading CalChanSummary');end;
    junk = hdfread(file_name, 'CalChanSummary');
    calchansummary = double(junk{1}');

    % Read NeN
% $$$ [junk,s]=hdfsw('readfield',swath_id,'NeN',[],[],[]);
% $$$ if s == -1; disp('Error reading NeN');end;
    junk = hdfread(file_name, 'NeN');
    nen = double(junk{1}');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (n0 > 0)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Read the date/time fields
% $$$ [junk,s]=hdfsw('readattr',swath_id,'start_Time');
        junk = hdfread(file_name, 'start_Time');
        start_Time = double(junk{1}(1));
        %
% $$$ [junk,s]=hdfsw('readattr',swath_id,'end_Time');
        junk = hdfread(file_name, 'end_Time');
        end_Time = double(junk{1}(1));
        %
% $$$ [junk,s]=hdfsw('readattr',swath_id,'granule_number');
        junk = hdfread(file_name, 'granule_number');
        granule_number = double(junk{1}(1));
        %
% $$$ [junk,s]=hdfsw('readattr',swath_id,'eq_x_tai');
        junk = hdfread(file_name, 'eq_x_tai');
        eq_x_tai = double(junk{1}(1));


        % Compute granule mean TAI
        meantai = 0.5*(start_Time + end_Time);
        clear start_Time end_Time


        % Read per scanline fields; expand to per FOV later
        %
        % calflag (nchan x natrack); read but do not convert to double yet
% $$$ [raw_calflag,s]=hdfsw('readfield',swath_id,'CalFlag',[],[],[]);
% $$$ if s == -1; disp('Error reading CalFlag'); end;
        junk = hdfread(file_name, 'CalFlag');
        raw_calflag = junk';
        %
        % satheight (1 x natrack)
% $$$ [junk,s]=hdfsw('readfield',swath_id,'satheight',[],[],[]);
% $$$ if s == -1; disp('Error reading satheight'); end;
        junk = hdfread(file_name, 'satheight');
        satheight = double(junk{1}'); 


        % Read in the channel freqs
% $$$ [junk,s]=hdfsw('readfield',swath_id,'spectral_freq',[],[],[]);
% $$$ if s == -1; disp('Error reading spectral_freq');end;
        junk = hdfread(file_name, 'spectral_freq');
        f = double(junk{1}');
        if (max(f) < -998)
            disp('WARNING! L1B file contains bad spectral_freq; using default')
            f = f_default;
        end
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'nominal_freq',[],[],[]);
% $$$ if s == -1; disp('Error reading nominal_freq');end;
        junk = hdfread(file_name, 'nominal_freq');
        nominal_freq = double(junk{1}');
        if (max(f) < -998)
            disp('WARNING! L1B file contains bad nominal_freq; using default')
            nominal_freq = f_default;
        end


        % Compute calnum
        %disp('computing calnum')
        [calnum, cstr] = data_to_calnum_l1b(meantai, nominal_freq, nen, ...
                                            calchansummary, raw_calflag);
        %
        clear raw_calflag calchansummary nen nominal_freq meantai


        % Declare temporary variables for expansion
        tmp_atrack = zeros(1,nobs);
        tmp_xtrack = zeros(1,nobs);
        tmp_zobs   = zeros(1,nobs);
        tmp_calflag = zeros(nchan,nobs);


        % Loop over along-track and fill in temporary variables
        ix=1:nxtrack;
        for ia=1:natrack
            iobs=nxtrack*(ia-1) + ix;
            %
            % Fill in cross-track
            tmp_atrack(iobs)=ia;
            tmp_xtrack(iobs)=ix;
            tmp_zobs(iobs)=satheight(ia)*1000;  % convert km to meters
            tmp_calflag(:,iobs) = repmat(calnum(:,ia),1,nxtrack);

        end
        %
        clear ix ia iobs calnum satheight


        % Subset temporary variables for state and re-assign to gdata
        gdata.findex = granule_number*ones(1,n0);
        gdata.atrack = tmp_atrack(i0);
        gdata.xtrack = tmp_xtrack(i0);
        gdata.zobs   = tmp_zobs(i0);
        gdata.calflag= tmp_calflag(:,i0);
        %
        clear tmp_atrack tmp_xtrack tmp_zobs tmp_calflag


        % Read in observed radiance, reshape, and subset for state.
        % Note: this is a very large array!
        % observed radiance is stored as (nchan x nxtrack x natrack)
% $$$ [junk,s]=hdfsw('readfield',swath_id,'radiances',[],[],[]); % (reads chan x FOV x scan)
% $$$ if s == -1; disp('Error reading radiances');end;
        junk = hdfread(file_name, 'radiances'); % (reads scan x FOV x chan)
                                                % reshape but do not convert to double yet (want chans x obs array)
        junk2 = reshape(junk, nobs, nchan)';
        clear junk
        % subset and convert to double
        gdata.robs1=double( junk2(:,i0) );
        clear junk2


        % Read the per FOV data
        gdata.rlat = rlat(i0);
        clear rlat
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'Longitude',[],[],[]);
% $$$ if s == -1; disp('Error reading longitude');end;
        junk = hdfread(file_name, 'Longitude');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.rlon = junk2(i0);
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'Time',[],[],[]);
% $$$ if s == -1; disp('Error reading rtime');end;
        junk = hdfread(file_name, 'Time');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.rtime = junk2(i0);
        gdata.rtime = gdata.rtime  + 12784 * 86400 + 27;

        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'scanang',[],[],[]);
% $$$ if s == -1; disp('Error reading scanang');end;
        junk = hdfread(file_name, 'scanang');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.scanang = junk2(i0);
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'satzen',[],[],[]);
% $$$ if s == -1; disp('Error reading satzen');end;
        junk = hdfread(file_name, 'satzen');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.satzen = junk2(i0);
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'satazi',[],[],[]);
% $$$ if s == -1; disp('Error reading satazi');end;
        junk = hdfread(file_name, 'satazi');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.satazi = junk2(i0);
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'solzen',[],[],[]);
% $$$ if s == -1; disp('Error reading solzen');end;
        junk = hdfread(file_name, 'solzen');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.solzen = junk2(i0);
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'solazi',[],[],[]);
% $$$ if s == -1; disp('Error reading solazi');end;
        junk = hdfread(file_name, 'solazi');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.solazi = junk2(i0);
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'topog',[],[],[]);
% $$$ if s == -1; disp('Error reading topog');end;
        junk = hdfread(file_name, 'topog');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.salti =junk2(i0);
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'landFrac',[],[],[]);
% $$$ if s == -1; disp('Error reading landFrac');end;
        junk = hdfread(file_name, 'landFrac');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.landfrac = junk2(i0);
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'scan_node_type',[],[],[]);
% $$$ if s == -1; disp('Error reading scan_node_type');end;
        junk = hdfread(file_name, 'scan_node_type');
        junk2 = reshape( ones(90,1)*double(junk{1}), 1,nobs);
        gdata.iudef(4,:) = junk2(i0);
        %
% $$$ [junk,s]=hdfsw('readfield',swath_id,'dust_flag',[],[],[]);
% $$$ if s == -1; disp('Error reading dust_flag');end;
        junk = hdfread(file_name, 'dust_flag');
        junk2 = reshape( double(junk'), 1,nobs);
        gdata.iudef(3,:) = junk2(i0);
        %

        clear junk junk2 i0


        % Close L1B granule file
% $$$ s = hdfsw('detach',swath_id);
% $$$ if s == -1; disp('Swatch detach error: L1b');end;   
% $$$ s = hdfsw('close',file_id);
% $$$ if s == -1; disp('File close error: L1b');end;


        % Determine number of known imperfect channels for each FOV
        gdata.robsqual = sum(gdata.calflag >= 64);

        % Assign attribute strings
        attr={{'profiles' 'rtime' 'Seconds since 0z, 1 Jan 1993'}, ...
              {'profiles' 'robsqual' 'Number of channels CalFlag+CalChanSummary>0'},...
              {'profiles' 'calflag' cstr},...
              {'profiles' 'Dust flag' '[1=true,0=false,-1=land,-2=cloud,-3=bad data] {dustflag}'},...
              {'profiles' 'Node' '[Ascend/Descend/Npole/Spole/Zunknown] {scan_node_type}'}};

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        disp('No good FOVs in L1B granule file:')
        disp(fn)

        meantime=[];
        f=[];
        gdata=[];
        attr = [];

    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%% end of function %%%
end

function [prof, pattr, aux] = read_airixcal(fn);

% function [prof, pattr, aux] = read_airixcal(fn);
%
% Input: fn is a AIRIXCAL netcdf/rtp3 file Output: rtp structures prof and
% pattr, aux structure with variables needed to form prof.calflag
%
% This routine only assigns a small subset of variables in the
% AIRIXCAL file that we want in RTP files.  Edit this file to add more
% variables.  You must be careful to assign the correct pattr to each
% udef, iudef.
%
% Created: S. Buczkowski June 27, 2018

% Is the file name appropriate for an AIRIXCAL file?
% Some file name logic here
% $$$ if length(strfind(fn,'L1B.Cal_Subset')) == 0
% $$$    disp('Warning!! Doesn''t appear to be an AIRIXCAL file')
% $$$ end

%------------------------------------------------------------------------------
% Assign variable names
%------------------------------------------------------------------------------
% Fixed rtp fields (airixcal_name rtp_name)
% Do radiances separately (no cell2mat needed)
    airixcal = {...
        'time'           'rtime'; ...
        'lat'            'rlat'; ...
        'lon'            'rlon'; ...
        'satalt'         'zobs'; ...  
        'findex'         'findex'; ...
        'atrack'         'atrack'; ...
        'xtrack'         'xtrack'; ...
        'satzen'         'satzen'; ...
        'solzen'         'solzen' ; ...
        'landfrac'       'landfrac'; ...
        'salt'           'salti'; ...
        'scanang'        'scanang'};

% $$$ % airixcal udef variables, in order (relative to pattr's)!
% $$$ airixcal_udef = {...
% $$$     'BT_diff_SO2' 'lp2395clim' 'cxlpn'  'cx2395' 'avnsst' ...
% $$$     'sst1231r5'   'cx1231'     'cx2616' 'cxq2'   'sun_glint_distance' };
    airixcal_udef = {};

    % airixcal iudef variables, in order (relative to pattr's)!
    airixcal_iudef = {'reason' 'siteid' 'ascflag'};

    % open netcdf file
    ncid = netcdf.open(fn, 'NC_NOWRITE');
    % AIRIXCAL files contain two groups: /IRInst and /MWInst for AIRS
    % and AMSU data. We are only concerned with /IRInst and will pull
    % data from that group only
    irinstID = netcdf.inqNcid(ncid, 'IRInst');

    %------------------------------------------------------------------------------
    % Read in data
    %------------------------------------------------------------------------------
    % Read all radiances
    varid = netcdf.inqVarID(irinstID, 'robs');
    prof.robs1 = netcdf.getVar(irinstID, varid);

    % Read in calflag
    varid = netcdf.inqVarID(irinstID, 'calflag');
    prof.calflag = netcdf.getVar(irinstID, varid);

    % Read in inst-dependent quality flag (0 implies good)
    varid = netcdf.inqVarID(irinstID, 'qual');
    qual = netcdf.getVar(irinstID, varid);

    % Read fixed rtp fields
    for i=1:length(airixcal)
        varid = netcdf.inqVarID(irinstID, airixcal{i,1});
        prof.(airixcal{i,2}) = netcdf.getVar(irinstID, varid)';
    end
    % Correct prof.rtime to TAI-UT1 from AIRS TAI93
    % See http://newsroom.gsfc.nasa.gov/sdptoolkit/primer/time_notes.html#TAI
    % TAI93 zero time is UTC 12 AM 1-1-1993.  To convert to TAI-UT1 we
    % must add the seconds from that date to 12 AM 1-1-1958 *and* add in
    % the 27 leap seconds from 1958 to 1993 (since EOS used a UTC time as
    % the start date).  mtime = datetime(1958,1,1,0,0,prof.rtime);
    seconds1958to1993 = 12784 * 86400 + 27;
    prof.rtime = prof.rtime + seconds1958to1993;

    % Read udefs (udefs handled below. this is a no-op at the moment)
    for i=1:length(airixcal_udef)
        varid = netcdf.inqVarID(irinstID, airixcal_udef{i});
        prof.udef(i,:) = netcdf.getVar(irinstID, varid);;
    end

    % Read iudefs
    for i=1:length(airixcal_iudef)
        varid = netcdf.inqVarID(irinstID, airixcal_iudef{i});
        prof.iudef(i,:) = netcdf.getVar(irinstID, varid);;
    end

    % Read in qcinfo
    varid = netcdf.inqVarID(irinstID, 'qcinfo');
    qcinfo = netcdf.getVar(irinstID, varid);

    % Read in iqcinfo
    varid = netcdf.inqVarID(irinstID, 'iqcinfo');
    iqcinfo = netcdf.getVar(irinstID, varid);

    % build udefs from qcinfo (airixcal does not have full airxbcal
    % compliment) (trying to match airxbcal indexing, though)
    prof.udef(1,:) = qcinfo(4,:);  % BT_diff_SO2
    prof.udef(10,:) = qcinfo(1,:);  % sun_glint_distance

    % get dust_flag from iqcinfo and stuff into iudef. requires
    % shifting around iudef as built above
    prof.iudef(4,:) = prof.iudef(3,:);  % move asc flag to iudef(4)
    prof.iudef(3,:) = iqcinfo(3,:);  % and insert dust_flag

% $$$ % Read fields needed for Scott's RTP calflag
    varid = netcdf.inqVarID(irinstID, 'nenmean');
    aux.NeN            = netcdf.getVar(irinstID, varid);

    varid = netcdf.inqVarID(irinstID, 'fchan');
    aux.nominal_freq   = netcdf.getVar(irinstID, varid);

    % close netcdf file
    netcdf.close(ncid);

    %------------------------------------------------------------------------------
    % Create attribute strings
    %------------------------------------------------------------------------------
    %  The iudef attributes must be in the same order as given in the
    %  airixcal_iudef and airixcal_udef cell arrays.  You must initialize
    %  the headers (here "profiles"), done in next command.
    pattr = set_attr('profiles','robs1',fn);
    pattr = set_attr(pattr,'rtime','TAI:1958');
    % iudef attributes
    pattr = set_attr(pattr, 'iudef(1,:)','Reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}');
    pattr = set_attr(pattr, 'iudef(2,:)','Fixed site number {sitenum}');
    pattr = set_attr(pattr, 'iudef(3,:)','Dust flag [1=true,0=false,-1=land,-2=cloud,-3=bad data] {dustflag}');
    pattr = set_attr(pattr, 'iudef(4,:)','Node [Ascend/Descend/Npole/Spole/Zunknown] {scan_node_type}');

    % udef attributes
    pattr = set_attr(pattr, 'udef(1,:)','SO2 indicator BT(1361) - BT(1433) {BT_diff_SO2}');
    pattr = set_attr(pattr, 'udef(10,:)','Sun glint distance');


end

function [prof, pattr, aux] = read_airxbcal(fn);

% function [prof, pattr, aux] = read_airxbcal(fn);
%
% Input: fn is a AIRXBCAL .hdf file Output: rtp structures prof and
% pattr, aux structure with variables needed to form prof.calflag
%
% This routine only assigns a small subset of variables in the
% AIRXBCAL file that we want in RTP files.  Edit this file to add more
% variables.  You must be careful to assign the correct pattr to each
% udef, iudef.
%
% Created: L. Strow, Jan. 8, 2015

% Is the file name appropriate for an AIRXBCAL file?
% Some file name logic here
    if length(strfind(fn,'L1B.Cal_Subset')) == 0
        disp('Warning!! Doesn''t appear to be an AIRXBCAL file')
    end

    %------------------------------------------------------------------------------
    % Assign variable names
    %------------------------------------------------------------------------------
    % Fixed rtp fields (airxbcal_name rtp_name)
    % Do radiances separately (no cell2mat needed)
    airxbcal = {...
        'Time'           'rtime'; ...
        'Latitude'       'rlat'; ...
        'Longitude'      'rlon'; ...
        'satheight'      'zobs'; ...
        'granule_number' 'findex'; ...
        'scan'           'atrack'; ...
        'footprint'      'xtrack'; ...
        'satzen'         'satzen'; ...
        'solzen'         'solzen' ; ...
        'LandFrac'       'landfrac'; ...
        'topog'          'salti'};

    % airxbcal udef variables, in order (relative to pattr's)!
    airxbcal_udef = {...
        'BT_diff_SO2' 'lp2395clim' 'cxlpn'  'cx2395' 'avnsst' ...
        'sst1231r5'   'cx1231'     'cx2616' 'cxq2'   'sun_glint_distance' };

    % airxbcal iudef variables, in order (relative to pattr's)!
    airxbcal_iudef = {'reason' 'site' 'dust_flag' 'scan_node_type'};

    %------------------------------------------------------------------------------
    % Read in data
    %------------------------------------------------------------------------------
    % Read all radiances
    prof.robs1 = hdfread(fn,'radiances')';

    % Read fixed rtp fields
    for i=1:length(airxbcal)
        prof.(airxbcal{i,2}) = cell2mat(hdfread(fn,airxbcal{i,1}));
    end
    % Correct prof.rtime to TAI-UT1 from AIRS TAI93
    % See http://newsroom.gsfc.nasa.gov/sdptoolkit/primer/time_notes.html#TAI
    % TAI93 zero time is UTC 12 AM 1-1-1993.  To convert to TAI-UT1 we
    % must add the seconds from that date to 12 AM 1-1-1958 *and* add in
    % the 27 leap seconds from 1958 to 1993 (since EOS used a UTC time as
    % the start date).  mtime = datetime(1958,1,1,0,0,prof.rtime);
    seconds1958to1993 = 12784 * 86400 + 27;
    prof.rtime = prof.rtime + seconds1958to1993;

    % Read udefs
    for i=1:length(airxbcal_udef)
        prof.udef(i,:) = cell2mat(hdfread(fn,airxbcal_udef{i}));
    end

    % Read iudefs
    for i=1:length(airxbcal_iudef)
        prof.iudef(i,:) = cell2mat(hdfread(fn,airxbcal_iudef{i}));
    end

    % Read visible sensor fields (needs transpose?)
    prof.udef([11 12 13],:) = hdfread(fn,'VisStdDev')';
    prof.udef([14 15 16],:) = hdfread(fn,'VisMean')';

    %------------------------------------------------------------------------------
    % Create attribute strings
    %------------------------------------------------------------------------------
    %  The iudef attributes must be in the same order as given in the
    %  airxbcal_iudef and airxbcal_udef cell arrays.  You must initialize
    %  the headers (here "profiles"), done in next command.
    pattr = set_attr('profiles','robs1',fn);
    pattr = set_attr(pattr,'rtime','TAI:1958');
    % iudef attributes
    pattr = set_attr(pattr, 'iudef(1,:)','Reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}');
    pattr = set_attr(pattr, 'iudef(2,:)','Fixed site number {sitenum}');
    pattr = set_attr(pattr, 'iudef(3,:)','Dust flag [1=true,0=false,-1=land,-2=cloud,-3=bad data] {dustflag}');
    pattr = set_attr(pattr, 'iudef(4,:)','Node [Ascend/Descend/Npole/Spole/Zunknown] {scan_node_type}');

    % udef attributes
    pattr = set_attr(pattr, 'udef(1,:)','SO2 indicator BT(1361) - BT(1433) {BT_diff_SO2}');
    pattr = set_attr(pattr, 'udef(2,:)','Climatological pseudo lapse rate threshold {lp2395clim}');
    pattr = set_attr(pattr, 'udef(3,:)','Spacial coherence of pseudo lapse rate {cxlpn}');
    pattr = set_attr(pattr, 'udef(4,:)','Spacial coherence of 2395 wn {cx2395}');
    pattr = set_attr(pattr, 'udef(5,:)','Aviation forecast sea surface temp {AVNSST}');
    pattr = set_attr(pattr, 'udef(6,:)','Surface temp estimate {sst1231r5}');
    pattr = set_attr(pattr, 'udef(7,:)','Spatial coherence of 1231 wn {cx1231}');
    pattr = set_attr(pattr, 'udef(8,:)','Spatial coherence of 2616 wn {cx2616}');
    pattr = set_attr(pattr, 'udef(9,:)','Spatial coherence of water vapor {cxq2}');
    pattr = set_attr(pattr, 'udef(10,:)','Sun glint distance');

    % Vis sensor attributes
    pattr = set_attr(pattr, 'udef(11,:)','Visible channel 1 STD {VIS_1_stddev}');
    pattr = set_attr(pattr, 'udef(12,:)','Visible channel 2 STD {VIS_2_stddev}');
    pattr = set_attr(pattr, 'udef(13,:)','Visible channel 3 STD {VIS_3_stddev}');
    pattr = set_attr(pattr, 'udef(14,:)','Visible channel 1 {VIS_1_mean}');
    pattr = set_attr(pattr, 'udef(15,:)','Visible channel 2 {VIS_2_mean}');
    pattr = set_attr(pattr, 'udef(16,:)','Visible channel 3 {VIS_3_mean}');

    % Read fields needed for Scott's RTP calflag
    aux.NeN            = hdfread(fn,'NeN')';
    aux.CalChanSummary = hdfread(fn,'CalChanSummary')';
    aux.nominal_freq   = cell2mat(hdfread(fn,'nominal_freq'))';

end
