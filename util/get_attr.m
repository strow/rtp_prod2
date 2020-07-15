function attr = get_attr( xattr , field , comp );

% function attr = get_attr( xattr , field , comp );
%
% Get a specified attribute and return it if it exists.
%
% Input:
%    xattr = RTP hattr or pattr (cell array with 1x3 elements per entry)
%    field = Search string of attribute
%    comp  = Field to compare or search, 1 = Name, 2 = Value (default: 1)
%
% Output:
%    attr  = attribute contents
%
% Examples:
%    get_attr(hattr,'pltfid')  % returns the platform ID
%    get_attr(pattr)  % displays a table of profile attributes
%
% See Also: set_attr, getudef

% Created 21 August 2009, Paul Schou  (paulschou.com)
% Bug fix 17 December 2009: nargin<2 -> nargin<3 (breno)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nattr=length(xattr);
if nargin == 1
  for ia=1:nattr
    disp(sprintf('%s%d)%16s = %s',xattr{ia}{1}(1),ia,xattr{ia}{2},xattr{ia}{3}))
  end
  return 
elseif nargin < 3
  comp = 1;
end

attr = '';
for ia=1:nattr
   if strcmpi(deblank(xattr{ia}{comp+1}),deblank(field))
       attr = xattr{ia}{4-comp};
       if length(attr) > 0 & attr(end) == 0; attr = attr(1:end-1); end
       return
   end
end

%%% end of function %%%
