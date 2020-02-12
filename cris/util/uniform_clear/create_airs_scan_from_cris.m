function l = create_airs_scan_from_cris(x, scanlines);

if nargin < 2 
    scanlines = 45; % default number of CrIS scanlines per granule
end

l = zeros(90,3*scanlines);
fprintf(1, 'debug notes\n')
size(l)
scanlines
k = [ 1 2 3];
l(:,1:3:3*scanlines-2) = reshape(x(k,:,:),90,scanlines);

k = [4 5 6];
l(:,2:3:3*scanlines-1) = reshape(x(k,:,:),90,scanlines);

k = [7 8 9];
l(:,3:3:3*scanlines) = reshape(x(k,:,:),90,scanlines);



