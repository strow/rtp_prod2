function calflag = loadcalflag(yn, airs_doy, previous)

MATBASEDIR = '/asl/data/airs/AIRIBRAD_subset';

if previous
% convert time to matlab datetime format
   yd = sprintf('%4d%03d', yn, airs_doy);
   t = datetime(yd, 'InputFormat', 'yyyyDDD');

% subtract one day and convert back to year and airs_doy
   yn  = year(t-1);
   airs_doy = day(t-1, 'dayofyear');
end

matfile = sprintf('%s/%4d/meta_%03d.mat', MATBASEDIR, yn, airs_doy);
% fprintf(1, 'Accessing %s for calflag data\n', matfile);
load(matfile, '-mat', 'calflag');

end
