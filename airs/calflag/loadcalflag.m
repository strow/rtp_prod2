function [status, calflag] = loadcalflag(yn, airs_doy, previous)
sFuncName = 'LOADCALFLAG';

MATBASEDIR = '/asl/data/airs/AIRIBRAD_subset';
calflag = 0;
status = 1;

if previous
% convert time to matlab datetime format
   yd = sprintf('%4d%03d', yn, airs_doy);
   t = datetime(yd, 'InputFormat', 'yyyyDDD');

% subtract one day and convert back to year and airs_doy
   yn  = year(t-1);
   airs_doy = day(t-1, 'dayofyear');
end

matfile = sprintf('%s/%4d/meta_%03d.mat', MATBASEDIR, yn, ...
                  airs_doy);
fn = dir(matfile);
if length(fn) == 0
    status = 98;
    return;
end
% fprintf(1, 'Accessing %s for calflag data\n', matfile);
load(matfile, '-mat', 'calflag');

end
