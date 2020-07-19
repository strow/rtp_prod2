function [mdrall] = load_mdr(mdr1,ind,mdrall);

% function [mdrall] = load_mdr(mdr1,ind,mdrall);
%
% Load an MDR structure with data for current scanline
%
% Input:
%    mdr1 - {structure} MDR for one scanline; final dim of
%       all fields must be 30.
%    ind - [1 x 30] indices of mdr1 in mdrall
%
% Input/Output:
%    mdrall - {structure} MDR large enough to contain data for
%       all scanlines
%

% Created: 23 September 2010, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin ~= 3)
   error('unepxected number of input arguments')
end
if (length(ind) ~= 30)
   error('argument ind must be length 30')
end

fnames = fieldnames(mdr1);
nf = length(fnames);
for ii=1:nf
   fstr = fnames{ii};
   eval(['d1=size(mdr1.' fstr ');'])
   eval(['dall=size(mdrall.' fstr ');'])
   nd = length(d1);
   if (min(ind) < 1 | max(ind) > dall(nd))
      error('some ind values do not fit into mdrall')
   end
   if (d1(nd) ~= 30)
      error(['final dim of all mdr1 fields must be 30, but ' fstr ' has ' ...
      int2str(d(nd))]);
   end
   switch nd
      case 2
         eval(['mdrall.' fstr '(:,ind)=mdr1.' fstr ';']);
      case 3
         eval(['mdrall.' fstr '(:,:,ind)=mdr1.' fstr ';']);
      otherwise
         error(['unexpected number of dimensions for field ' fstr])
   end
end

%%% end of function %%%
