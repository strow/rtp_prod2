function [prof] = xyz_subset_rtp(profin,indp);

%% copied from ~sergio/MATLABCODE/RTPMAKE/CLUST_RTPMAKE/CLUSTMAKE_ERA_CLOUD_NADIR/xyz_subset_rtp.m

fieldsIN  = fieldnames(profin);
for ii = 1 : length(fieldsIN)
  str = ['blah = profin.' fieldsIN{ii} ';'];
  eval(str);
  [mm,nn] = size(blah);
  if mm == 1
    %% this is like eg p.stemp = 1 x N ---> 1 x M
    str = ['prof.' fieldsIN{ii} ' = blah(indp);'];
    eval(str)
  else
    %% this is like eg p.robs1 = L x N ---> L x M
    str = ['prof.' fieldsIN{ii} ' = blah(:,indp);'];
    eval(str)
  end										    
end
