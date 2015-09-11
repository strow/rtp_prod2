function [h,ha,p,pa] = cat_rtp_dir(fdir);
%
% Concatenate all rtp files in a directory.
% Assumes they all have identical fields, and attributes, but not size
% Also assumes that prof.rlat exists.  Can switch to a better var if needed

% Get file names
a = dir(fullfile(fdir,'*.rtp'));
nfiles = length(a);

% Need number of obs per file for indexing
for i=1:nfiles
   rlat = hdfread(fullfile(fdir,a(i).name),'profiles','Fields','rlat');
   ns = size(rlat{1});
   n(i) = ns(2);
end

% Indices for each file into daily file
i2 = cumsum(n);
i1 = i2 - n + 1;
ntot = sum(n);  

% Allocate memory, get fieldnames and types from first file
[hx,hax,px,pax] = rtpread(fullfile(fdir,a(1).name));
% Just use first file to get final h, ha, and pa
h = hx; ha = hax; pa = pax;
pf = fieldnames(px);
m = length(pf);
% Actual allocation
for i=1:m
   [r c] = size(px.(pf{i}));
   dtype = class(px.(pf{i}));
   p.(pf{i}) = zeros(r,ntot,dtype);
end

% Now fill arrays, looping over files and fieldnames
for i=1:nfiles
   [hx,hax,px,pax] = rtpread(fullfile(fdir,a(i).name));
   for j=1:m
      p.(pf{j})(:,i1(i):i2(i)) = px.(pf{j});
   end
end

