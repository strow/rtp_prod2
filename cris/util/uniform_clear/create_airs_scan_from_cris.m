function l = create_airs_scan_from_cris(x);

l = zeros(90,135);

k = [ 1 2 3];
l(:,1:3:133) = reshape(x(k,:,:),90,45);

k = [4 5 6];
l(:,2:3:134) = reshape(x(k,:,:),90,45);

k = [7 8 9];
l(:,3:3:135) = reshape(x(k,:,:),90,45);



