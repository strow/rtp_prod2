function [reason ikeep] = random_eq_area(prof)
%
% NAME:
%
% SYNOPSIS:
%
% USEAGE:
%
% INPUTS:
%
% OUTPUTS:
%
% DEPENDENCIES: None.
%       
% NOTES:
%
    addpath /home/sbuczko1/git/rtp_prod2/util
    
    % filter out desired FOVs/scan angles 
    fors = [1:30];  % full swath
    nadir = ismember(prof.xtrack,fors);
    % rtp has a 2GB limit so we have to scale number of kept FOVs
    % to stay within that as an absolute limit. Further, we
    % currently restrict obs count in random to ~20k to match
    % historical AIRXBCAL processing
    limit = 20000;  % number of obs to keep
    nswath = 23;  % length of ccast granules
    ngrans = 480;  % number of granules per day
    nfovs = 4;  % number of FOVs per FOR
    maxobs = nswath * length(fors) * nfovs * ngrans;
    scale = (limit/maxobs)*4; % preserves ~40k obs/day (without
                                % multiplier, only getting
                                % ~10-12k counts ?? 
    randoms = get_equal_area_sub_indices(prof.rlat, scale);
    ikeep = find(nadir & randoms);
    reason = 1;


% $$$ 
% $$$ tim1  = prof.rtime(1);
% $$$ rand('seed',tim1(1,1));
% $$$ 
% $$$ satza = prof.satzen;
% $$$ 
% $$$ [mm nn]  = size(prof.rlat);
% $$$ reason   = uint16(zeros(mm,nn));
% $$$ 
% $$$ fov1     = find(prof.ifov == 1);
% $$$ center0  = find(prof.xtrack == 15 | prof.xtrack == 16);     % full set IFOVs to randomize
% $$$ center1  = find(prof.xtrack == 15 & prof.ifov == 2);        % use for finding polar granule
% $$$ %center = center(1:9:length(center));
% $$$ 
% $$$ vx    = find(abs(prof.satzen) < 3.5);      % center FORs, same as center0 (FOR 15 + 16)
% $$$ sn    = length(vx);
% $$$ 
% $$$ vxr   = vx(randperm(sn));
% $$$ 
% $$$ % find the mean latitude of this granule based on center FORs:
% $$$ mnlat   = mean(prof.rlat(vx));
% $$$ 
% $$$ nsave = floor(sn*abs(cos(mnlat/57.3)) + 0.5);
% $$$ 
% $$$ if abs(mean(prof.rlat(vx))) > 30
% $$$   PX = [-6.781163592359652e-06 8.826415250236825e-04 -3.817478053811275e-02 1.534451094844683e+00];
% $$$   adj_factor = polyval(PX,abs(mean(prof.rlat(vx))));
% $$$   %fprintf(1,'     *** *** *** adjusting nsave by factor %8.6f \n',adj_factor);
% $$$   nsave = ceil(nsave * adj_factor);
% $$$ end
% $$$ 
% $$$ nsave1 = nsave;
% $$$ % apply 'notch filter' to samples from 78 to 82 latitude:
% $$$  xx     = [-4:.2:4];
% $$$  norm   = normpdf(xx,0,1);         % [1x41] normal - set to peak at 90-deg
% $$$  xbands = [76:0.5:96]; nxbands = length(xbands);
% $$$  for j=1:15                        % 76 to 83 latitude is adequate
% $$$    clear innotch;
% $$$    innotch =  find( abs(prof.rlat(vx)) > xbands(j) & abs(prof.rlat(vx)) <= xbands(j+1) );
% $$$    if(innotch)
% $$$      notch_fact = (max(norm) - norm(j+5))/max(norm);       % +5 to get steeper slope
% $$$      nsave      = ceil(nsave1 * notch_fact);
% $$$    end
% $$$  end
% $$$  
% $$$ % reduce further:
% $$$ vc = vxr(1:2:nsave);
% $$$ 
% $$$ % set the reason flag
% $$$ reason(vc) = bitset(reason(vc),4);               % bit 4=1 :- dec value 8.
% $$$ 
% $$$ % set index of obs to keep
% $$$ ikeep = vc;

%{
% optional plotting
  figure(1);clf;plot(pd.rlat(vc),'k.');grid;     % rlat(vx) or vc

%}
