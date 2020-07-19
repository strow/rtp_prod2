function ib = hot_scene_check(head, prof, btthresh, idtest_lw, idtest_sw);

% find indices into spectrum for the test ichans
[idtestx,indtest_lw,junk] = intersect(head.ichan,idtest_lw);
[idtestx,indtest_sw,junk] = intersect(head.ichan,idtest_sw);

% find the actual wavenumbers associated with the test ichans
ftest_lw = head.vchan(indtest_lw);
ftest_sw = head.vchan(indtest_sw);

% Compute BT of test channels
% Longwave
% Determine indices of idtest in head.ichan
btobs_lw = real(rad2bt(ftest_lw, prof.robs1(indtest_lw,:)));
btobs_sw = real(rad2bt(ftest_sw, prof.robs1(indtest_sw,:)));
mbt_lw = nanmean(btobs_lw);
mbt_sw = nanmean(btobs_sw);

% HOT scenes 
ib = find(mbt_lw > btthresh | mbt_sw > btthresh);


