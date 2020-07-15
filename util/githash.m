function [status,ghash] = githash;
% GITHASH - return hash of current repo
% 
% RETURNS
%   status: 0 if in a valid repo, 128 (non-zero) otherwise
%   ghash: HEAD git hash of current repo

[status, ghash] = system('git rev-parse HEAD 2> /dev/null');
if 0 == status   
    ghash = ghash(1:end-1);
else
    ghash = 'Not a repo';
end

%% ****end function githash****