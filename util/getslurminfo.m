function [sScratchPath, sID] = getslurminfo()
% GETSLURMINFO retrieve path to scratch space and slurm_procid
%
% 

sNodeID = getenv('SLURM_PROCID');
sScratchPath = getenv('JOB_SCRATCH_DIR');
if ~isempty(sNodeID) && ~isempty(sScratchPath)
    sTempPath = sScratchPath;
    sID = sNodeID;
else
    sTempPath = '/tmp';
    rng('shuffle');
    sID = sprintf('%03d', randi(999));
end

%% ****end function getslurminfo****