function [l1c] = read_airs_l1c(fn);

l1c.Latitude = hdfread(fn,'Latitude');
l1c.Longitude = hdfread(fn,'Longitude');
l1c.Time = hdfread(fn,'Time');
l1c.radiances = hdfread(fn,'radiances');
l1c.scanang = hdfread(fn,'scanang');
l1c.satzen = hdfread(fn,'satzen');
l1c.satazi = hdfread(fn,'satazi');
l1c.solzen = hdfread(fn,'solzen');
l1c.solazi = hdfread(fn,'solazi');
l1c.sun_glint_distance = hdfread(fn,'sun_glint_distance');
l1c.topog = hdfread(fn,'topog');
l1c.topog_err = hdfread(fn,'topog_err');
l1c.landFrac = hdfread(fn,'landFrac');
l1c.landFrac_err = hdfread(fn,'landFrac_err');
l1c.ftptgeoqa = hdfread(fn,'ftptgeoqa');
l1c.zengeoqa = hdfread(fn,'zengeoqa');
l1c.demgeoqa = hdfread(fn,'demgeoqa');
l1c.state = hdfread(fn,'state');
l1c.Rdiff_swindow = hdfread(fn,'Rdiff_swindow');
l1c.Rdiff_lwindow = hdfread(fn,'Rdiff_lwindow');
l1c.SceneInhomogeneous = hdfread(fn,'SceneInhomogeneous');
l1c.dust_flag = hdfread(fn,'dust_flag');
l1c.dust_score = hdfread(fn,'dust_score');
l1c.spectral_clear_indicator = hdfread(fn,'spectral_clear_indicator');
l1c.BT_diff_SO2 = hdfread(fn,'BT_diff_SO2');
l1c.AB_Weight = hdfread(fn,'AB_Weight');
l1c.L1cProc = hdfread(fn,'L1cProc');
l1c.L1cSynthReason = hdfread(fn,'L1cSynthReason');
l1c.NeN = hdfread(fn,'NeN');
l1c.Inhomo850 = hdfread(fn,'Inhomo850');

return