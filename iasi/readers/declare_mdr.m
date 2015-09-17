function [mdrall] = declare_mdr(mdr1,nmdr);

% function [mdrall] = declare_mdr(mdr1,nmdr);
%
% Declare an MDR structure for all concatenated scanline data
% using the MDR for one scanline.  This code assumes the final
% dimension of all mdr1 fields is 30, and the output final
% dimension is 30*nmdr.
%
% Input:
%    mdr1 - {structure} MDR for one scanline; final dim of
%       all fields must be 30.
%    nmdr - [1 x 1] number of scanline MDRs to concatenate
%
% Output:
%    mdrall - {structure} MDR large enough to contain data for
%       all scanlines
%

% Created: 23 September 2010, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dn = 30*nmdr;

fnames = fieldnames(mdr1);
nf = length(fnames);
for ii=1:nf
   fstr = fnames{ii};
   eval(['d=size(mdr1.' fstr ');'])
   nd = length(d);
   if (d(nd) ~= 30)
      error(['final dim of all MDR fields must be 30, but ' fstr ' has ' ...
      int2str(d(nd))]);
   end
   dx = d;
   dx(nd) = dn;
   eval(['mdrall.' fstr '=zeros(dx,class(mdr1.' fstr '));']);
end

%%% end of function %%%
