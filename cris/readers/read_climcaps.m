% CLIMCAPS Cloud-cleared netcdf reader
function [data] = read_climcaps(nfile)

% CLIMCAPS CCR netcdf files store most everything in the global '/'
% level

info = ncinfo(nfile);
nvar = length(info.Variables);

% for now slurp in everything we can. We'll sort things out in the
% calling function.
data = [];
for i = 1:nvar
    fname = info.Variables(i).Name;
    data.(fname) = h5read(nfile, ['/' fname]);
end
