function latbins = equal_area_spherical_bands(N);

%% given an interegr N, this code finds the latitude vector such that the sphere
%% segment surface area between any pair is the same ie
%% Area from latbins(1) to latbins(2) == area between latbins(i) to latbins(i+1)
%%                                    == area between latbins(N-1) to latbins(N)
%% points start at equator (lat 0) and go up toward norht pole, then mirrored for south pole
%%
%% see /home/sergio/MATLABCODE/RTPMAKE/CLUST_RTPMAKE/CLUSTMAKE_ERA_CLOUD_NADIR
addpath /home/sbuczko1/git/rtp_prod2/extutils

%N = 20;

latbins(1) = 0;
for ii = 2 : N
  sinx = 1/N + sin(latbins(ii-1)*pi/180);
  x = asin(sinx)*180/pi;
  latbins(ii) = x;
end
latbins(end+1) = 90;
latbins = [-fliplr(latbins(2:end)) latbins];

[A,V] = surfacearea_sphericalzones(latbins);
latbinsx = 0.5 * (latbins(1:end-1) + latbins(2:end));
%{
fprintf(1,'clear sky latbinsbins  : %8.6f \n',sum(A))
plot(latbinsx,A,'ro-')
plot(latbinsx,A/max(A),'ro-')
title('Equal Area latbins')
%}    
