
function b = isleap(y)

b = NaN;

if rem(y, 4) ~= 0
  b = 0;
elseif rem(y, 100) ~= 0
  b = 1;
elseif rem(y, 400) ~=0
  b = 0;
else
  b = 1; 
end

