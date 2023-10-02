function [isvalidcfg] = is_config_valid(cfg)

% establish local directory structure
currentFilePath = mfilename('fullpath');
[cfpath, cfname, cfext] = fileparts(currentFilePath);

% initialize output to fail condition
isvalidcfg = false;

% all rtp processing needs these
base_fields = {'inst', 'model', 'klayers_exec', 'sartaclr_exec'};

% instrument specific config fields
switch cfg.inst
  case 'cris'
    inst_fields = {'nsarta', 'nguard'};
  case 'airs'
    inst_fields = {};
  case 'iasi'
    inst_fields = {};
  otherwise
    fprintf(2, '*** %s: Unknown instrument specified in cfg.inst: %s\n', ...
            cfname, cfg.inst);
    return
end

% config specific to rtp run type (clear, allfov, etc)
switch cfg.rtpfilter
  case 'allfov'
    rtype_fields = {'sartacld_exec', 'clear', 'cloud', 'cumsum'};
  case 'clear'
    rtype_fields = {};
  case 'random' 
    rtype_fields = {};
  case 'dcc'
    rtype_fields = {};
  case 'site'
    rtype_fields = {};
  otherwise
    fprintf(2, '*** %s: Unknown rtp filter type specified in cfg.rtpfilter: %s\n', ...
            cfname, cfg.rtptype);
    return
end
    
necessary_fields = [base_fields inst_fields rtype_fields ];

% validation routine should also check that paths to filelists,
% input/output dirs, klayers and sarta executables are valid
true_fields = isfield(cfg, necessary_fields);
allfieldsvalid = all(true_fields);
if ~allfieldsvalid
    fprintf(2, '*** %s: Configuration missing necessary fields:\n', ...
            cfname);
    fprintf(2, '\t%s\n', necessary_fields{find(~true_fields)});
    fprintf(2, '*** Exiting\n')
    return
end

% check that paths to ancillary files are valid
fpaths = {cfg.klayers_exec, cfg.sartaclr_exec};
if isfield(cfg, 'sartacld_exec')
    fpaths{end+1} = cfg.sartacld_exec;
end
true_paths = isfile(fpaths);
allpathsvalid = all(true_paths);
if ~allpathsvalid
    fprintf(2, '*** %s: Configuration has invalid file paths:\n', ...
            cfname);
    fprintf(2, '\t%s\n', fpaths{find(~true_paths)});
    fprintf(2, '*** Exiting\n')
    return
end

% all checks passed. config appears valid
isvalidcfg = true;
    

