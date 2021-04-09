function [sJobId, sTempPath] = genscratchpath()
% GENSCRATCHPATH  Generate path to scratch/temp file space
%
% Takes into account differences in behavior between slurm and
% non-slurm job execution and the differing placement of
% temporary/scratch space between cluster compute nodes and cluster
% head node/non-cluster machines
%

sJobId = getenv('SLURM_JOB_ID');

% if not a cluster node under slurm control, make random directory
if isempty(sJobId)
    rng('shuffle', 'twister');
    sJobId = sprintf('%08d', randi(99999999));
end

sTempPath = sprintf('/scratch/%s',sJobId);

if exist(sTempPath) == 0
    fprintf(1, '>>>> %s does not exist. Creating\n', sTempPath);
    mkdir(sTempPath);
end
