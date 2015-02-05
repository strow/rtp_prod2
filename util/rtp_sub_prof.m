function psub=rtp_sub_prof(prof, subset)
% function psub=ProfSubset2(prof, subset)
% 
% Generate a subset of profiles in prof. 
% Subset is an array of selected profiles [p1 p2 ... pn].
%
% Breno Imbiriba 2007.03.10

fnames=fieldnames(prof);
nnames=length(fnames);

nprofs=length(subset);

psub=[];
for ic=1:nnames
   field=getfield(prof,fnames{ic});
   rank=ndims(field);
   dims=size(field);
   if(max(subset)>dims(rank))
      warning('Requesting too many profiles. Setting to max.');
      subset=min(subset,dims(rank));
   end
   dims(rank)=nprofs;

   clear index;
   for ij=1:rank
      index{ij}(1:dims(ij))=[ 1:dims(ij)];
   end
   index{rank}(1:dims(rank))=[subset];
   field=getfield(prof, fnames{ic}, index);
   psub=setfield(psub,fnames{ic},field);
end

   
