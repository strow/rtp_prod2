% Steven, need to find another way to get calflag,
% this is going to take too long.

% Using on-line AIRIBRAD this takes 12 hours/year, vs
% 92 hours/year for opendap

% One time only (not really needed)
calflag = zeros(240,135,2378);

% Pick a day
cd /asl/data/airs/AIRIBRAD/2013/122

% Listing of granule files
a = dir('AIRS*.hdf');

% Loop over files, all data in one array per day
for i=1:240;
    calflag(i,:,:) = hdfread(a(i).name,'CalFlag');
end;