function [status, matchedcalflag] = mkmatchedcalflag(yn, doy, prof)
sFuncName = 'MKMATCHEDCALFLAG';

matchedcalflag = zeros(length(prof.robs1),2378);

% jan 1, 2013 keeps failing because of an array size
% mismatch. Let's trap for this in a genreal sense
if length(prof.robs1) ~= length(prof.findex)
    fprintf(1, [sFuncName, ' :: robs and findex array do not ' ...
                'match length. Failing.']);
    status = 99;
    return;
end

% load calflag mat file
[status, pdaycalflag] = loadcalflag(yn, doy, 1);
if status == 98
    fprintf(1, [sFuncName, [' :: Previous day calflag metadata file ' ...
                        'missing\n']]);
    return;
end
[status, calflag] = loadcalflag(yn, doy, 0);
if status == 98
    fprintf(1, [sFuncName, [' :: Curent day calflag metadata file ' ...
                        'missing\n']]);
    return;
end

% Make an array which matches prof arrays to
% calflag elements. This is done through granule number
% (prof.findex) and scan line number (prof.atrack)
for i=1:length(prof.robs1)
   if prof.findex(i) == 0
      matchedcalflag(i,:) = pdaycalflag(240, prof.atrack(i), :);
   else
      matchedcalflag(i,:) = calflag(prof.findex(i), prof.atrack(i),:);
   end
end

status = 1;

end