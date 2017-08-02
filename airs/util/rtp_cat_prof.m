function [h, ha, p, pa] = rtp_cat_prof(sScratchPath, sNodeID)

fprintf(1, '>>> Concatenating psarta output files\n');
fileregexp=fullfile(sScratchPath, sprintf('psarta_%s_*_out.rtp', sNodeID))
asFiles = dir(fileregexp);
               
% $$$ keyboard
% $$$ sScratchPath
% $$$ sNodeID
% $$$ asFiles(1).name

% read first filename
fprintf(1, '>>> Reading temp file: %s\n', fullfile(sScratchPath, asFiles(1).name));
[h, ha, p, pa] = rtpread(fullfile(sScratchPath, asFiles(1).name));

% build structure descriptors
fnames = fieldnames(p);
nnames = length(fnames);

% loop over remaining files and concatenate p structures
%    we can't just concatenate the prof structures together as it is
%    the internal array records that we need to group. Therefore this
%    concatenation needs to be done field by field
for i=2:length(asFiles)
    [h_t, ha_t, p_t, pa_t] = rtpread(fullfile(sScratchPath, asFiles(i).name));

    % now the concatenation
    for j=1:nnames
        p.(fnames{j}) = [p.(fnames{j}) p_t.(fnames{j})];
    end

end
