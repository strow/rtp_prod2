% form_emis_interpolant.m
%
% Create emissivity interpolant structures for rtp_prod use.

% Load compressed emissivities
load Data/ci_all_no_nan

% For circular interpolation
% Dec is month 0, then Jan:Dec, Jan is month 13
ci_all = vertcat(ci_all(12,:,:),ci_all,ci_all(1,:,:));

% Dan's database is on a 0.5 degree grid
gs = 0.5;
dlon = (-180 + gs/2):gs:(180 - gs/2);
dlat = (-90  + gs/2):gs:(90 - gs/2);

% Need ndgrid syntax matrices for interpolant (14 "months")
[glon,glat,dmon]=ndgrid(dlon,dlat,0:13);

% Form interpolant structures
for i=1:10  % Using 10 SVD vectors
   cx = reshape(squeeze(ci_all(:,i,:)),14,360,720);
   ctemp = permute(cx,[3 2 1]);
   danz(i).emis = griddedInterpolant(glon,glat,dmon,ctemp);
end

save danz_interpolant danz
