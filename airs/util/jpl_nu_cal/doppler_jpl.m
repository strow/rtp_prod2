function dnu_ppm = doppler_jpl(scan_node_type,xtrack,satzen,satazi,sat_lat);
% Compute Doppler shift of spectrum

omega = 7.292E-5;  % radians/sec, earth's rotational velocity
Re = 6.3781E8;     % cm, earth radius
c = 2.99792E10;    % cm/sec, speed of light

% satzen must have a sign, set negative for RHS when looking in direction of motion
airs_first_xtrack_past_nadir = 46;
k = find(xtrack >= airs_first_xtrack_past_nadir);
satzen(k) = -satzen(k);

% Doppler shift
dnu_ppm = 1E6*((omega*Re)/c).*sin(deg2rad(satzen)).*cos(deg2rad(sat_lat)).*abs(sin(deg2rad(satazi)));

% Sign change for descending
idesc = (scan_node_type == 1);
dnu_ppm(idesc) = -dnu_ppm(idesc);   
