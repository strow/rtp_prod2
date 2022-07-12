function s = read_netcdf(fn);

% A generic reader for netcdf files.  Only reads first-level groups

% Top Level
ni = ncinfo(fn);
if isfield(ni,'Variables')
   n = length(ni.Variables);
   for i=1:n
      try
         s.(strrep(ni.Variables(i).Name,' ','_')) = ncread(fn,ni.Variables(i).Name);
      catch
%         s.(ni.Variables(i).Name) = h5read(fn, strcat('/',ni.Variables(i).Name));
         s.(strrep(ni.Variables(i).Name,' ','_')) = h5read(fn, ['/' ni.Variables(i).Name]);
      end
   end
end

% Groups
ng = length(ni.Groups);
for g = 1:ng
   n = length(ni.Groups(g).Variables);
   for i=1:n
      try
         s.(strrep(ni.Groups(g).Name,' ','_')).(strrep(ni.Groups(g).Variables(i).Name,' ','_')) = ncread(fn,['/' ni.Groups(g).Name '/' ni.Groups(g).Variables(i).Name]);
      catch
         s.(strrep(ni.Groups(g).Name,' ','_')).(strrep(ni.Groups(g).Variables(i).Name,' ','_')) = h5read(fn,['/' ni.Groups(g).Name '/' ni.Groups(g).Variables(i).Name]);
      end
   end
end
