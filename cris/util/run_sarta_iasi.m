function [head, hattr, prof, pattr] = run_sarta_iasi(head, hattr, prof, pattr, cfg)
funcname = 'run_sarta_iasi';
fprintf(1, '>> Running %s \n', funcname);

sarta_exec  = ['/asl/packages/sartaV108/BinV201/' ...
               'sarta_iasi_may09_wcon_nte'];
if isfield(cfg, 'sarta_exec')
    sarta_exec = cfg.sarta_exec;
end

ichan_ccast = head.ichan;

sTempPath = cfg.sTempPath;
sID = cfg.sID;

% Now run IASI SARTA 
% Remove CrIS channel dependent fields before doing IASI calc
if (isfield(head,'vchan'))
    %%** removes the user space frequency channel array but leaves
    %%the channel index array (which sarta needs?)
  head = rmfield(head,'vchan');
end
if (isfield(prof,'robs1'))
  prof = rmfield(prof,'robs1');
  head.pfields = head.pfields - 4;
end
if (isfield(prof,'rclr'))
  prof = rmfield(prof,'rclr');
  head.pfields = head.pfields - 2;
end
if (isfield(prof,'calflag'))
  prof = rmfield(prof,'calflag');
end

% Run IASI SARTA
%%** fiasi is a LUT for the IASI frequency space channel
%%allocations
ltemp = load('/asl/data/iremis/danz/iasi_f', 'fiasi'); % load fiasi
fiasi = ltemp.fiasi;
clear ltemp;

% First half of IASI
%%** replace both cris ichan and vchan with iasi equivalents (??
%%but without guard channels??). This is done because we have a
%%sarta model for iasi but not for cris, correct?? Why, exactly did
%%we do the field removal of head.vchan a few lines ago but not
%%similarly remove ichan? Here, we replace both with iasi
%%equiv. so, why the removal?
head.nchan = 4231;
head.ichan = (1:4231)';
head.vchan = fiasi(1:4231);
fn_rtpi = fullfile(sTempPath, ['cris_' sID '_rtpi.rtp']);
rtpwrite(fn_rtpi,head,hattr,prof,pattr);
fn_rtprad = fullfile(sTempPath, ['cris_' sID '_rtprad.rtp']);
disp('running SARTA for IASI channels 1-4231')
eval(['! ' sarta_exec ' fin=' fn_rtpi ' fout=' fn_rtprad ' > ' ...
      sTempPath '/sartastdout1.txt']);
%psarta_run(fn_rtpi, fn_rtprad, sarta_exec);
[head, hattr, prof, pattr] = rtpread(fn_rtprad);
rad_pt1 = prof.rcalc;
% Second half of IASI
head.nchan = 4230;
head.ichan = (4232:8461)';
head.vchan = fiasi(4232:8461);
rtpwrite(fn_rtpi,head,hattr,prof,pattr);
disp('running SARTA for IASI channels 4232-8461')
eval(['! ' sarta_exec ' fin=' fn_rtpi ' fout=' fn_rtprad ' > ' ...
      sTempPath '/sartastdout2.txt' ]);
%psarta_run(fn_rtpi, fn_rtprad, sarta_exec);
[head, hattr, prof, pattr] = rtpread(fn_rtprad);
rad_pt2 = prof.rcalc;

%
rad_iasi = [rad_pt1; rad_pt2];
clear rad_pt1 rad_pt2

% Convert IASI radiances to CrIS
opt.hapod = 0;  % Want sinc from iasi2cris
opt.resmode = 'hires2'; % CrIS mode after Dec. 4, 2014
opt.nguard = cfg.nguard; % adding 2 guard channels

% Convert Iasi to CrIS
[tmp_rad_cris, f_cris] = iasi2cris(rad_iasi,fiasi,opt);
%%% trying to add 2 guard channels. This check will need to be
%%% redone but, for now, I will just remove it
% $$$ % f_cris are real channels, no guard channels
[num_ichan_iasi, num_profs] = size(tmp_rad_cris);
% $$$ if num_ichan_iasi ~= 2211
% $$$    disp('Error: iasi2cris returning wrong channels');
% $$$ end

% Full g4 radiance variable
rad_cris = ones(length(ichan_ccast),num_profs).*NaN;
% Indices (not channels) for real radiances
ireal = find(ichan_ccast <= 2211);

% $$$ rad_cris(ireal,:) = tmp_rad_cris;
rad_cris = tmp_rad_cris;
% Go get output from klayers, which is what we want except for rclr
[head, hattr, prof, pattr] = rtpread(cfg.fn_rtp2);
% $$$ prof = rmfield(prof, 'rclr');
% Insert rclr for CrIS derived from IASI SARTA
prof.rclr = real(rad_cris); 

end  % end function