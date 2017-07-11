function readAIRIBRADcalflag (year, daynum)

% process one day of AIRIBRAD files (240 granule files) to extract
% CalFlag values and store resulting calflag array in a mat file named
% for the day number

% This routine is designed to be called from the year directory
% level in the AIRIBRAD directory hierarchy

%%%%%%%%%%%%%%%%%%%% WARNING %%%%%%%%%%%%%%%%%%%%
% this version will have VERY LITTLE error checking for
% expediancy. IT IS ASSUMED THAT DIRECTORIES EXIST FOR READING AND
% WRITING. It is NOT assumed that a day has a full compliment of
% granule files. The loop over granules is range-controlled by the
% number of files in the daynum directory
%%%%%%%%%%%%%%%%%%%% WARNING %%%%%%%%%%%%%%%%%%%%
 
dataroot = '/asl/data/airs/AIRIBRAD';
yearroot = fullfile(dataroot, sprintf('%4d', year));
fileroot = fullfile(yearroot, sprintf('%03d',daynum));

outID = 1; % messages to stdout
fprintf(outID, 'Accessing AIRIBRAD files for %4d, daynum %03d\n', year, daynum);

% One time only (not really needed)
calflag = zeros(240,135,2378);

% Listing of granule files
filelist = dir(fullfile(fileroot, 'AIRS*.hdf'));

% Loop over files, all data in one array per day
numfiles = size(filelist);
fprintf(outID, '\tDirectory contains %d granule files.\n', numfiles(1));

for i=1:numfiles(1);
    filepath = fullfile(fileroot, filelist(i).name);
    calflag(i,:,:) = hdfread(filepath,'CalFlag');
end;

% redirect output to the AIRIBRAD_subset hierarchy and save calflag
matpath = fullfile(strcat(dataroot, '_subset'), sprintf('%4d',year), sprintf('meta_%03d.mat', daynum));
save(matpath, 'calflag');
fprintf(outID, '\tProcessing complete. CalFlag MAT file saved to %s.\n', matpath);

end % end of readAIRIBRADcalflag