%*************************************************
% Execute user-defined paths *********************
REPOBASEPATH = '/home/sbuczko1/git/';
% $$$ REPOBASEPATH = '/asl/packages/';

% rtp_prod2_PROD
addpath(sprintf('%s/rtp_prod2_PROD/util', REPOBASEPATH);
addpath(sprintf('%s/rtp_prod2_PROD/grib', REPOBASEPATH);
addpath(sprintf('%s/rtp_prod2_PROD/emis', REPOBASEPATH);
addpath(genpath(sprintf('%s//airs', REPOBASEPATH)));

% swutils (will move under matlib soon)
addpath(sprintf('%s/swutils', REPOBASEPATH);

% matlib
addpath(sprintf('%s/matlib/clouds/sarta', REPOBASEPATH)  % driver_cloudy_sarta

%*************************************************
