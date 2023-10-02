function [h,ha,p,pa] = rtp_add_model(h,ha,p,pa,opts)

    % Add profile data
model = cfg.model;
fprintf(1, '>>> Add model: %s...', model)
switch model
  case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr,cfg);
  case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
end

% rtp now has profile and obs data ==> 5
head.pfields = 5;
[nchan,nobs] = size(prof.robs1);
head.nchan = nchan;
% $$$ head.ngas=2;
fprintf(1, 'Done\n');


end
