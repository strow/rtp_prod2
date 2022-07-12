function [head, hattr, prof, pattr] = rtp_add_model(head, hattr, ...
                                                  prof, pattr, cfg)

switch cfg.model
  case 'ecmwf'
    [prof,head,pattr]  = fill_ecmwf(prof,head,pattr);
  case 'era'
    [prof,head,pattr]  = fill_era(prof,head,pattr);
  case 'merra'
    [prof,head,pattr]  = fill_merra(prof,head,pattr);
  case 'era5'
    [prof,head,pattr]  = fill_era5(prof,head,pattr);
end
% check that we have same number of model entries as we do obs because
% corrupt model files will leave us with an unbalanced rtp
% structure which WILL fail downstream (ideally, this should be
% checked for in the fill_* routines but, this is faster for now)
if size(prof.robs1,2) ~= size(prof.gas_1,2)
    fprintf(2, ['**> Add model %s failed. Unbalanced number of obs ' ...
                'and gas_1 entries.\n'], cfg.model);
    prof = struct();
    return;
end

% set status info
head.pfields = 5;  % robs, model
                
% set attribute describing model
set_attr('profiles' 'model' cfg.model)