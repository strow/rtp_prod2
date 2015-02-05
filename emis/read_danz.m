function [emis,e] = read_danz(fnc);
% Reader for Dan Zhou's latest emissivity database

% Get the basis vectors
fnv = 'DanZ_data/IASI_B_EV_FUNC_GLOBAL_V4.bin';
fid = fopen(fnv,'r','b');
v   = fread(fid,[8461,11],'float64');
fclose(fid);

% First vector is an offset
e.eoff = v(:,1);
% Rest are the orthogonal basis vectors
u = v(:,2:11);
clear v;

% Get the coefficients for some month (09)
%fnc = 'Data/IASI_FEMI_CLIMATOLOGY_09_2007-2012.bin';
fid  = fopen(fnc,'r','b');
nrec = 720*360;
a    = fread(fid,[16,nrec],'float');
fclose(fid);

% Assign variables
e.landflag = a(1,:);  % Just 0,1
e.lat   = a(2,:);
e.lon   = a(3,:);
e.spres = a(4,:);
e.tskin = a(5,:);
e.c     = a(6:15,:);  % The coefficients

clear a;

% Compute emissivity for all points
emis = u*e.c;
for i=1:nrec
   emis(:,i) = emis(:,i) + e.eoff;
end
emis = 0.995 - exp(-0.693147181 - exp(emis));  % This is slow

% Points we should not use, including ocean
e.ibad = find( e.landflag ==0 | e.landflag > 1 | e.tskin < 50);
 