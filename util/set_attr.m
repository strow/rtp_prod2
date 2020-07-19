function xattr = set_attr( xattr , field , value , type );

% function attr = set_attr( xattr , field , value );
%
% Set a specified attribute and return the updated attributes
%
% Input:
%    xattr = RTP hattr or pattr (cell array with 1x3 elements per entry)
%    field = Name of attribute
%    value = Value to set
%
% Output:
%    xattr = new attribute cell array
%
% When setting an attribute for the first time use:
%    xattr = set_attr('header', field, value);
%    xattr = set_attr('profiles', field, value);
%
% See also: get_attr, getudef

% Created 21 August 2009, Paul Schou  (paulschou.com)
% Updated 18 June 2010 - added capability to create new attribute cell array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isstr(xattr)
   if strcmp(xattr,'header') | strcmp(xattr,'profiles')
     type = xattr;
   else
     error('Only header or profiles attributes may be declared')
   end
   xattr = {};
end
nattr=length(xattr);

for ia=1:nattr
   if strcmpi(xattr{ia}{2},field)
       xattr{ia}{2} = field;
       xattr{ia}{3} = value;
       return
   end
end

% make a new entry if it does not exist already
if nattr == 0
   xattr{end+1} = {type, field, value};
else
   xattr{end+1} = {xattr{1}{1}, field, value};
end

%%% end of function %%%
