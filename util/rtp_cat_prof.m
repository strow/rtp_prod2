function p = rtp_cat_prof(p1, p2)
% build structure descriptors
fnames = fieldnames(p1);
nnames = length(fnames);
% now the concatenation
for j=1:nnames
    p.(fnames{j}) = [p1.(fnames{j}) p2.(fnames{j})];
end


