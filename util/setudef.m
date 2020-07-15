function [prof pattr] = setudef(prof, pattr, dat, fname, ftext, type, force)
% function [prof pattr] = setudef(prof, pattr, dat, fname, ftext type, force)
%
% Set an udef/iudef variable in the prof/pattr RTP structure, using the 
% "dat" data array. 
% 
% prof  - RTP profile structure containing the udef/iudef fields
% pattr - profile attribute structure
% dat   - data array
% fname - the field name (short name) 
% ftext - the explanation of the field (if necessary)
% type  - 'udef' or 'iudef'
% force - force a particular index 1..20 for udef, 1..10 for iudef
%         this will overwrite whatever data is in there and rewrite 
%         the attributes
%
% Breno Imbiriba - 2013.01.25

  global NMAXUDEF
  global NMAXIUDEF

  NMAXUDEF = 20;
  NMAXIUDEF= 10;


  isudef = strcmpi(type,'udef');

  % Force?
  if(nargin()==7)
    [prof pattr] = set_xdef_l(prof, pattr, dat, fname, ftext, isudef, force);
    return
  end

  % Check if the variable is already there
  index = find_variable_xdef_l(pattr, fname, ftext, isudef);
  
  if(numel(index)==0)

    % Variable doesn't exist
    % Find a empty udef/iudef index to save the data
    empty = find_empty_xdef_l(pattr,  isudef);
  
    % Test if there's not empty slot available
    if(numel(empty)==0)
      say('No udef/iudef index available!');
      return
    else
      loc = empty;
    end 
  else
    loc = index;
  end

  % Now we can save the data at the xdef(loc,:) place.
  % save it.

  [prof pattr] = set_xdef_l(prof, pattr, dat, fname, ftext, isudef, loc);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function index = find_variable_xdef_l(pattr, fname, ftext, isudef)

  index = find_variable_xdef(pattr, fname, ftext, isudef);

%  % Look at the attributes for a variable {fname} or 
%  % for the long text "ftext {fname}"
%  % If found, return its xdef location
%
%  if(isudef)
%    xdef='udef'; nx=4; 
%  else
%    xdef='iudef'; nx=5;
%  end
%
%  nattr=numel(pattr);
% 
%  lfound=false;
%
%  for iattr=1:nattr
%    longname = pattr{iattr}{3};
%    
%    o_brackets = strfind(longname,'{');
%    c_brackets = strfind(longname,'}');
%    shortname = longname(o_brackets+1:c_brackets-1);
%    
%    if(numel(shortname)>0)
%      if(strcmpi(shortname,fname))
%	% Found the variable using the short name
%	lfound=true;
%	break;
%      end
%    elseif(strcmpi(longname,[ftext ' {' fname '}']))
%      % Found the variable using the long name
%      lfound=true;
%      break
%    end
%  end
%
%  if(lfound)
%    pfname = pattr{iattr}{2};
%
%    % Now extract the xdef number  
%    iloc = strfind(pfname,xdef);
%    index = str2num(pfname(iloc+nx+1:end-3));
%  else
%    index=[];
%  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function empty = find_empty_xdef_l(pattr, isudef)

  % loop over all the pattr fields, 
  % looking for the existence of udef/iudef  fields, 
  % saving the numbers in a vector and 
  % look for an empty slot.
  global NMAXUDEF
  global NMAXIUDEF

  if(isudef)
    xdef='udef'; nx=4; NMAX=NMAXUDEF;
  else
    xdef='iudef'; nx=5; NMAX=NMAXIUDEF;
  end

  nattr=numel(pattr);
  nvec=[];
  ivec=0;

  for iatt=1:nattr
    pfname = pattr{iatt}{2};
    loc = strfind(pfname,xdef);
    if(numel(loc)>0)
      if(loc(1)==1)
	ivec=ivec+1;
	nvec(ivec) = str2num(pfname(loc+nx+1:end-2));
      end
    end
  end

  % nvec is the vector of udef/iudef in use
  % get the first available one
  vfree = setdiff([1:NMAX],nvec);

  if(numel(vfree)==0)
    empty=[];
  else
    empty=vfree(1);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [prof pattr] = set_xdef_l(prof, pattr, dat, fname, ftext, isudef, slot)

  pattr = set_attr_l(pattr, fname, ftext, isudef, slot);

  prof  = set_prof_l(prof, dat, isudef, slot);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function pattr = set_attr_l(pattr, fname, ftext, isudef, slot)

  % look for the existence of udef(slot,:) as actual profile field name
  % If found, replace it's text content by the provided fname and ftext
  % If not found, create another pattr entry. 

  nattr=numel(pattr);

  % construct prof field name 
  if(isudef)
    pfname = ['udef(' num2str(slot,'%2d') ',:)'];
  else
    pfname = ['iudef(' num2str(slot,'%2d') ',:)'];
  end

  % conctruct description
  if(numel(fname)>0)
    dscrpt = [ftext ' {' fname '}' ];
  else
    dscrpt = ftext;
  end

  % Seach for existing fields in pattr
  for iattr=1:nattr
    if(strcmp(pfname,pattr{iattr}{2}))
      % Found! Now replace description
      pattr{iattr}{3} = dscrpt;
      return
    end
  end

  % haven't found anything. Create a new attribute field
  pattr{nattr+1}={'profiles',pfname, dscrpt};

end


function prof = set_prof_l(prof,dat,isudef, slot)

  if(isudef)
    pfname = ['udef(' num2str(slot,'%2d') ',:)'];
  else
    pfname = ['iudef(' num2str(slot,'%2d') ',:)'];
  end


  eval(['prof.' pfname ' = dat;'])  

end





