%*************************************************
% Execute user-defined paths *********************
REPOBASEPATH = '/home/sbuczko1/git/';
% $$$ REPOBASEPATH = '/asl/packages/';

% rtp_prod2
addpath(sprintf('%s/rtp_prod2/util', REPOBASEPATH);
addpath(sprintf('%s/rtp_prod2/grib', REPOBASEPATH);
addpath(sprintf('%s/rtp_prod2/emis', REPOBASEPATH);
addpath(genpath(sprintf('%s//airs', REPOBASEPATH)));

% swutils (will move under matlib soon)
addpath(sprintf('%s/swutils', REPOBASEPATH);

% matlib
addpath(sprintf('%s/matlib/clouds/sarta', REPOBASEPATH)  % driver_cloudy_sarta

%*************************************************
