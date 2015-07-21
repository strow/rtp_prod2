function prof = expand_hires_cristrack(prof0);

% Each granule has 60 * (2*(3x3)) * 30 = 16200 spectra, out of which 9 are nadir135*6=810 near nadir spectra
% Each granule has 60 atrack, then the unique 30 xtrack are 3x3 fovs
% so the nadir "xtracks" would be 14,15 which would give 9+9 = 18 samples per atrack, quite a few!!!

prof = prof0;
% oo = find(prof0.atrack == 41); scatter(prof0.rlon(oo(1:9)),prof0.rlat(oo(1:9)),100,1:9,'filled'); colorbar
% seem to be of the form 9 6 3    as opposed to AIRS 7 8 9
%                        8 5 2                       4 5 6
%                        7 4 1                       1 2 3


unique_atrack = unique(prof.atrack);
unique_xtrack = unique(prof.xtrack);

for ii = 1 : length(unique_atrack)
  atrack = unique_atrack(ii);
  for jj = 1 : length(unique_xtrack)
    xtrack = unique_xtrack(jj);
    fov = find(prof.atrack == atrack & prof.xtrack == xtrack);
    prof.expand1to9lats(fov) = sort(prof.rlat(fov));
    prof.expand1to9(fov)    =  fov(5) - fov;
    prof.expand_xtrack(fov) =  mod(fov-1,90) + 1;
    prof.expand_atrack(fov) =  double(idivide(int32(fov-1),int32(90)) + 1);  %that's integer division
  end
end

profin = prof;

%{
[Y,I] = sort(prof.expand_atrack);
indp = 1 : length(prof.rlat);
indp = I;
fieldsin  = fieldnames(profin);
for ii = 1 : length(fieldsin)
  str = ['blah = profin.' fieldsin{ii} ';'];
  eval(str);
  [mm,nn] = size(blah);
  if mm == 1
    %% this is like eg p.stemp = 1 x N ---> 1 x M
    str = ['prof.' fieldsin{ii} ' = blah(indp);'];
    eval(str)
  else
    %% this is like eg p.robs1 = L x N ---> L x M
    str = ['prof.' fieldsin{ii} ' = blah(:,indp);'];
    eval(str)
  end										    
end

index = (prof.expand_atrack-1)*90 + prof.expand_xtrack;
center = find(prof.expand_xtrack == 45 & prof.expand1to9 == -4);
plot(prof.expand_atrack(center),prof.rlat(center))

oo = find(prof.xtrack == 15);
scatter(prof.rlon(oo),prof.rlat(oo),index(oo))
scatter(prof.rlon(oo),prof.rlat(oo),30,index(oo),'filled'); colorbar

center = oo(1:9:length(oo));
plot(prof.expand_atrack(center),prof.rlat(center))

keyboard

%}

