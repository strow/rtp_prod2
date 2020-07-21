function [h ha p pa]=rtpread_12(fname)
% function [h ha p pa]=rtpread_12(fname)
%
% Read a pair of IASI data files, whose names are fname_1 and fname_2
% Concatenate the data by radiances

% Update: 16 July 2009, Scott Hannon - add calflag
% Update: 28 Apr 2010, S.Hannon - set "h" to "h1" and update vcmax and
%    nchan/ichan/vchan
% Update: 20 May 2010, P. Schou - added the ability to read in 1/2Z files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist([fname '_1'],'file')
  [h1 ha p1 pa]=rtpread([fname '_1']);
  [h2 xx p2 xx]=rtpread([fname '_2']);
elseif exist([fname '_1Z'],'file')
  [h1 ha p1 pa]=rtpread([fname '_1Z']);
  [h2 xx p2 xx]=rtpread([fname '_2Z']);
elseif exist([fname(1:end-2) '_1'],'file')
  [h1 ha p1 pa]=rtpread([fname(1:end-2) '_1']);
  [h2 xx p2 xx]=rtpread([fname(1:end-2) '_2']);
elseif exist([fname(1:end-3) '_1Z'],'file')
  [h1 ha p1 pa]=rtpread([fname(1:end-3) '_1Z']);
  [h2 xx p2 xx]=rtpread([fname(1:end-3) '_2Z']);
else
  [h ha p pa] = rtpread(fname); return
end


% Join by channel

% header
h = h1;
if (isfield(h1,'nchan'))
   h.nchan=h1.nchan+h2.nchan;
end
if (isfield(h1,'ichan'))
   h.ichan=[h1.ichan; h2.ichan];
end
if (isfield(h1,'vchan'))
   h.vchan=[h1.vchan; h2.vchan];
end
if (isfield(h2,'vcmax'))
   h.vcmax = h2.vcmax;
end

% profile
p=p1;
if(isfield(p1,'robs1'))
  p.robs1=cat(1,p1.robs1,p2.robs1);
end
if(isfield(p1,'rcalc'))
  p.rcalc=cat(1,p1.rcalc,p2.rcalc);
end
if(isfield(p1,'calflag'))
  p.calflag=cat(1,p1.calflag,p2.calflag);
end

%%% end of function %%%
