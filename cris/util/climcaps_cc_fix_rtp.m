function climcaps_cc_fix_rtp(rtp_file)

% CLIMCAPS CCR rtp files ahve a problem with the concatenated qc
% and err. They were assigned initially to the wrong array types:
% qc bytes were assigned to a float and err float were assigned to
% an int8.

% Since we also have a collection of the same qc and err data
% pulled out by band, we can read those mat files, reshape and
% concatenate new qc and err arrays and replace those in the rtp
% file

% parse rtp_file of form
% /asl/rtp/cris/climcaps_snpp_ccr_hires/random/2018/023/SNDR.SNPP.CRIMSS_20180123_random.rtp
% and pull out the 20180123 timestamp
[path, filename, ext] = fileparts(rtp_file);
C = strsplit(filename, '_');
tstamp = C{2};

% read in the rtp file (only really need the prof struct)
[h,ha,p,pa] = rtpread(rtp_file);

% build filename and path to the corresponding qc/err mat file. This
% will be of the form
% /asl/rtp/cris/climcaps_snpp_ccr_hires/random/2018/023/climcaps_ccr_20180123_rad_qc_err.mat
mat_file = fullfile(path, sprintf('climcaps_ccr_%8s_rad_qc_err.mat', ...
                                  tstamp));

% load the mat file (actually only need rad_[lms]w_{err,qc})
loadvars = {'rad_lw_err','rad_lw_qc','rad_mw_err','rad_mw_qc','rad_sw_err','rad_sw_qc'};
load(mat_file,loadvars{:});

% reshape and concatenate err and qc data from the mat file
err = cat(1, rad_lw_err, rad_mw_err, rad_sw_err);
qc = cat(1, rad_lw_qc, rad_mw_qc, rad_sw_qc);

p.rerr = err;
p.rqc = qc;

rtpwrite(sprintf('%s.1',rtp_file),h,ha,p,pa)

% done