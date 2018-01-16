function [prof, pattr] = build_satlat(prof, pattr)

UDEFINDEX = 20;
% **** udef and iudef definitions and tracking are a mish-mash of
% **** procedures throughout rtp_prod code. This needs to be
% **** cleaned up

% Build CrIS sub-satellite lat point
% based on LLS code snippet to test
for i=1:length(prof.rlat)
    atrack = prof.atrack(i);
    k = find(prof.atrack == atrack & (prof.xtrack == 15 | prof.xtrack == ...
                                      16));
    sat_lat = nanmean(prof.rlat(k));
    prof.udef(UDEFINDEX,i) = sat_lat;
end
pattr{end+1} = {'profiles' sprintf('udef(%d,:)', UDEFINDEX) 'sub-satellite latitude'}';

end
