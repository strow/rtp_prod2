function dat = getudef(prof,pattr,field)
%function dat = getudef(prof,pattr,field)
%
% Scan the RTP udef/iudef fields for given field name (short or long form) 
% and return its data.
%
% If no field is given a structure containing the whole udef/iudef 
% data is returned instead.
%
% prof  - RTP profile structure (where the udef/iudef fields are defined)
% pattr - RTP profile attribute array
%
% field - The field name. It can be in the long or short form.
%
%         The long form is the whole text in the attribute explanation
%
%         The short form is the text contained in the braces {}
%         In the short form you also have the "_bit" sulfix that is 
%         automatically removed so it SHOULD NOT be added to the name
% 
% Examples:
%   Get the reason_bit attribute
%   using the name (note not using _bit)
%
%     reason = getudef(prof,pattr,'reason');
%
%   using the whole name
%
%     reason = getudef(prof,pattr,'Reason [1=clear,2=site,4=high cloud,8=random] {reason_bit}');
%
%   
%     udef_struct = getudef(prof,pattr);
% 
% See also: get_attr, set_attr
%
% Paul Schou (created)
% Breno Imbiriba



% Error out if 'field' is present but empty
if nargin == 3 & isempty(field)
  error('Error: no field name specified')
end

% Loop over profile attributes
for i = 1:length(pattr)

  % Test if attribute has a "short name"
  longname = pattr{i}{3};
  shortname = regexp(pattr{i}{3},'{[a-zA-Z0-9_]*}','match');

  if ~isempty(shortname)
    % if so, get the name and test for the _bit sulfix
    fname = shortname{1}(2:end-1);
    if strcmp(fname(max(1,end-3):end),'_bit'); 
      fname= fname(1:end-4); 
    end
  else
    % If there's not shortname then we don't need a fieldname
    fname = [];
  end

  % Get actual profile udef/iudef variable name
  sudef = pattr{i}{2};

  % add some backwards compatibility for L1bCM
  if strcmp(sudef(1:min(6,end)),'L1bCM '); 
    sudef = sudef(7:end); 
  end
 
  if(nargin < 3)
    % If asking for all udefs only return something if fieldname is defined
    if(numel(fname)>0)
      dat.(fname) = eval(['prof.' sudef]);
    end
  end

  % If asking for a specific field, there are two options:
  % search for shortname (which is corrected and put into fname) or longname. 
  % 
  if(nargin==3)
    if(numel(fname)>0) % can search by shortname
      if(strcmpi(deblank(fname),deblank(field)))
	% match shortname?
	dat = eval(['prof.' sudef]);
	return
      elseif(strcmpi(deblank(longname),deblank(field)))
	% match longname?
        dat = eval(['prof.' sudef]);
	return
      end
    else % can't seach by shortname, only longname
      if(strcmpi(deblank(longname),deblank(field)))
	 % match longname?
	 dat = eval(['prof.' sudef]);
        return
      end
    end
  end
%  elseif strcmp(pattr{i}{3}(1:min(length(field),end)),field)
%    %disp(['  ' field '= prof.' sudef]);
%    dat = eval(['prof.' sudef]);
%    return
%  end
end

if nargin == 3
  disp(['Warning [getudef]: field {' field '} not found in pattr']);
  dat=[];
end

end

