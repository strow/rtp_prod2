function matchedcalflag = mkmatchedcalflag(yn, doy, prof)

% load calflag mat file
pdaycalflag = loadcalflag(yn, doy, 1);
calflag     = loadcalflag(yn, doy, 0);

% Make an array which matches prof arrays to
% calflag elements. This is done through granule number
% (prof.findex) and scan line number (prof.atrack)
matchedcalflag = zeros(length(prof.robs1),2378);
for i=1:length(prof.robs1)
   if prof.findex(i) == 0
      matchedcalflag(i,:) = pdaycalflag(240, prof.atrack(i), :);
   else
      matchedcalflag(i,:) = calflag(prof.findex(i), prof.atrack(i),:);
   end
end
