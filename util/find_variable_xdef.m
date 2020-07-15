function index = find_variable_xdef(pattr, fname, ftext, isudef)
% function index = find_variable_xdef(pattr, fname, ftext, isudef)
% 
% Locate the index of the required profile attribute:
% 
% pattr - profile attribute structure
% fname - variable name (short name)
% ftext - description (used to form the long name: [ftext '{' fname '}']
% isudef- 1=udef/0=iudef
%
% If you set ftext='' then this will only return the index if the short name
% is defined.
%
% Breno Imbiriba - 2013.01.28

  % Look at the attributes for a variable {fname} or 
  % for the long text "ftext {fname}"
  % If found, return its xdef location

  if(isudef)
    xdef='udef'; nx=4;
  else
    xdef='iudef'; nx=5;
  end

  nattr=numel(pattr);

  lfound=false;

  for iattr=1:nattr
    longname = pattr{iattr}{3};

    o_brackets = strfind(longname,'{');
    c_brackets = strfind(longname,'}');
    shortname = longname(o_brackets+1:c_brackets-1);

    if(numel(shortname)>0)
      if(strcmpi(shortname,fname))
        % Found the variable using the short name
        lfound=true;
        break;
      end
    elseif(strcmpi(longname,[ftext ' {' fname '}']))
      % Found the variable using the long name
      lfound=true;
      break
    end
  end

  if(lfound)
    pfname = pattr{iattr}{2};

    % Now extract the xdef number  
    iloc = strfind(pfname,xdef);
    index = str2num(pfname(iloc+nx+1:end-3));
  else
    index=[];
  end

end

