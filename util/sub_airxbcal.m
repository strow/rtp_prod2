function prof = sub_airxbcal(prof, lmax);

l = length(prof.rlat);  % Present number of obs

if( (l - lmax) > 0)
   k      = find( prof.iudef(1,:) == 1);  % Clear only obs
   ko     = find( prof.iudef(1,:) ~= 1);  % All others
   kl     = length(k);    % Number of clear only obs
   kmax   = kl - (l - lmax); % Number of clear to keep
   rr     = randperm(kl,kmax); % Pick kmax random from 1:kl, no
                               % overlap
   rr_all = union(k(rr),ko);   % Switch to global indices
   prof   = rtp_sub_prof(prof,rr_all);
end

end

