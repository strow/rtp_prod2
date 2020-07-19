
function d = daydif(y1, y2)

d = 0;

for y = y1 : y2 - 1

  if isleap(y)
    d = d + 366;
  else
    d = d + 365;
  end

end

