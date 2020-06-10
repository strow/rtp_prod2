function [sNodeID, sTempPath] = genscratchpath()
% GENSCRATCHPATH  Generate path to scratch/temp file space
%
% Takes into account differences in behavior between slurm and
% non-slurm job execution and the differing placement of
% temporary/scratch space between cluster compute nodes and cluster
% head node/non-cluster machines
%

sNodeID = getenv('SLURM_PROCID');
sScratchPath = getenv('JOB_SCRATCH_DIR');
if ~isempty(sNodeID) && ~isempty(sScratchPath)
    sTempPath = sScratchPath;
else
    sTempPath = '/scratch';
    rng('shuffle', 'twister');
    sNodeID = sprintf('%08d', randi(99999999));
end

end
