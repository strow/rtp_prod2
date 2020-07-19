
function [root,aux] = rd_crisL1B(fname);

root.info = ncinfo(fname);
for i = 1:length(root.info.Variables)
  varname = root.info.Variables(i).Name;
  data = h5read(fname,['/' varname]);
  eval(['root.' varname ' = data;'])
end

if nargout == 2
  aux.info = ncinfo(fname,'aux');
  for i = 1:length(aux.info.Variables)
    varname = aux.info.Variables(i).Name;
    data = h5read(fname,['/aux/' varname]);
    eval(['aux.' varname ' = data;'])
  end
end




