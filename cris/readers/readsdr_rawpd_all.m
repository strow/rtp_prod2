function [pd pd_file_a pd_aggr_a pd_sdr_a pd_gran0_a] = readsdr_rawpd_all(file);

%function [pd pd_file_a pd_aggr_a pd_sdr_a pd_gran0_a]=readsdr_rawpd_all(file);
%
% Read a CrIS HDF5 SDR "Product_Data" file and return the entire
% contents in a structure, now including attributes
% Note: see "readsdr_rawgeo.m" for CrIS HDF5 SDR "Geolocation" file.
%
% Input:
%    hfile : [string] name of CrIS HDF5 SDR "Product_Data" file
%
% Output:
%    pd   : [structure] CrIS SDR Product_Data with 28 fields
%

% Created: 18 Nov. 2011, L. Strow, starting with readsdr_rawpd.m, Mostly from
%                        UW version (Lori B.), moved attributes to different
%                        structures.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

d = dir(file);
if (length(d) ~= 1)
   hfile
   error('bad filename')
end

%Get hdf5 file info
info=hdf5info(file);

%Read in GroupHierarchy.Attributes
% File attributes
nfields = length(info.GroupHierarchy.Attributes);
pd=[];
for ii=1:nfields
    fname = basename(info.GroupHierarchy.Attributes(ii).Name);
    eval(['pd_file_a.' fname '=info.GroupHierarchy.Attributes(ii).Value.Data;'])
end

% Read Groups(1).Groups.Datasets
% All data, main pd structure
nfields = length(info.GroupHierarchy.Groups(1).Groups(1).Datasets);
for ii=1:nfields
   fname = basename(info.GroupHierarchy.Groups(1).Groups(1).Datasets(ii).Name);
   eval(['pd.' fname '=hdf5read(info.GroupHierarchy.Groups(1).Groups(1).Datasets(ii));'])
end

% Read in Groups(2).Groups.Attributes
% Data product attributes cris-sdr
nfields = length(info.GroupHierarchy.Groups(2).Groups.Attributes);
for ii=1:nfields
   fname = basename(info.GroupHierarchy.Groups(2).Groups.Attributes(ii).Name);
   if strcmp(class(info.GroupHierarchy.Groups(2).Groups.Attributes(ii).Value),'hdf5.h5string')==1
      nh5str=length(info.GroupHierarchy.Groups(2).Groups.Attributes(ii).Value);
      for jj=1:nh5str
         eval(['pd_sdr_a.' fname '{jj}=(info.GroupHierarchy.Groups(2).Groups.Attributes(ii).Value(jj).Data);'])
      end
   else
      eval(['pd_sdr_a.' fname '=(info.GroupHierarchy.Groups(2).Groups.Attributes(ii).Value);'])
   end
end

% Read in Groups(2).Groups.Datasets(1).Attributes
% CrIS-SDR_Aggr attributes
nfields = length(info.GroupHierarchy.Groups(2).Groups.Datasets(1).Attributes);
for ii=1:nfields
   fname = basename(info.GroupHierarchy.Groups(2).Groups.Datasets(1).Attributes(ii).Name);
   if strcmp(class(info.GroupHierarchy.Groups(2).Groups.Datasets(1).Attributes(ii).Value),'hdf5.h5string')==1
      nh5str=length(info.GroupHierarchy.Groups(2).Groups.Datasets(1).Attributes(ii).Value);
      for jj=1:nh5str
         eval(['pd_aggr_a.' fname '{jj}=(info.GroupHierarchy.Groups(2).Groups.Datasets(1).Attributes(ii).Value(jj).Data);'])
      end
   else
      eval(['pd_aggr_a.' fname '=(info.GroupHierarchy.Groups(2).Groups.Datasets(1).Attributes(ii).Value);'])
   end
end

% Read in Groups(2).Groups.Datasets(2).Attributes
% CrIS-SDR_Gran_0 info (assuming 1 granule??)
nfields = length(info.GroupHierarchy.Groups(2).Groups.Datasets(2).Attributes);
for ii=1:nfields
   fname = basename(info.GroupHierarchy.Groups(2).Groups.Datasets(2).Attributes(ii).Name);
   fname= strrep(fname,'-','_');
   if strcmp(class(info.GroupHierarchy.Groups(2).Groups.Datasets(2).Attributes(ii).Value),'hdf5.h5string')==1
      nh5str=length(info.GroupHierarchy.Groups(2).Groups.Datasets(2).Attributes(ii).Value);
      for jj=1:nh5str
         eval(['pd_gran0_a.' fname '{jj}=(info.GroupHierarchy.Groups(2).Groups.Datasets(2).Attributes(ii).Value(jj).Data);'])
      end
   else
      eval(['pd_gran0_a.' fname '=(info.GroupHierarchy.Groups(2).Groups.Datasets(2).Attributes(ii).Value);'])
   end
end
