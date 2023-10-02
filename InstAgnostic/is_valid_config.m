function a = is_valid_config(cfg, cfg_type)

% cfg is a cfg struct as built from an ini file by ini2struct (may
% swap to yaml at some point but that should be transparent to this
% routine)

% cfg_type is a string to define the type of processing to be done
% which will dictate what configuration items are required for
% processing

a = true;

switch(cfg_type)
    case 'allfov':
      necessary_fields = {'inst', 'model', 'klayers_exec', 'sartaclr_exec', ...
                          'sartacld_exec'};
end

true_fields = istrue(cfg, necessary_fields);
if ~all(true_fields)
    fprintf(2, '**> Configuration missing necessary fields:\n
    missing_fields = necessary_fields(find(~true_fields));
    fprintf(2, '\t%s\n', missing_fields{:});
    a = false;
end

