function create_rtp_hires(doy, year)
% CREATE_RTP_HIRES  process a day of CrIS high-res data
%
% 

set_process_dirs

addpath(genpath('/asl/rtp_prod/cris'));
% $$$ addpath ~/Work/Rtp
% $$$ addpath /asl/matlib/aslutil

% Create list of files to process
sPath='/asl/data/cris/ccast/sdr60_hr';
datadir = sprintf('%s/%d/%03d', sPath, year, doy);

a = dir(fullfile(datadir,'SDR*.mat'));

for i=1:length(a)
   fnInput = fullfile(datadir1,a(i).name);
   
   % fnOutput
   [fpath, fname, ext] = fileparts(fnInput);

   % Strings needed for file names
   cris_doystr  = sprintf('%03d',doy);
   cris_yearstr = sprintf('%4d',year);

   fnOutput = fullfile(cris_hires_out_dir, 
end

   

   % call process_cris_hires to process this granule
   process_cris_hires(fnInput, fnOutput)

end

end  % end function