function file_names = rtpread_12(rtp_outfile,head,hattr,prof,pattr)
% function file_names = rtpread_12(fname,head,hattr,prof,pattr)
%
% Write a pair of IASI data files, whose names are {fname}_1 and {fname}_2
% Split the data by radiances

% Created: 18 Oct 2010, Paul Schou
% Update: 04 Jan 2011, S.Hannon - change "nchan < 5000" to "nchan <= 4321"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmpfile1 = mktemp();
tmpfile2 = mktemp();
%tmpfile1 = [tmpfile '_1'];
%tmpfile2 = [tmpfile '_2'];

if(isfield(prof,'rcalc'))
    rcalc = prof.rcalc;
end
if(isfield(prof,'robs1'))
    robs1 = prof.robs1;
end
if(isfield(prof,'calflag'))
    calflag = prof.calflag;
end
if rtp_outfile(end) == 'Z'
  z = 'Z';
  rtp_outfile = rtp_outfile(1:end-1);
else
  z = '';
end

vchan = head.vchan;
nchan = length(vchan);

% if we only need to write one part, then we will write it out
if nchan <= 4231
  rtpwrite(tmpfile1,head,hattr,prof,pattr);
  movefile(tmpfile1,rtp_outfile);
  file_names = {rtp_outfile};
  return
end

split = ceil(nchan/2);
part1 = (1:split)'; %'
part2 = (split+1:nchan)'; %'

% PART 1
head.nchan = length(part1);
head.ichan = part1;
head.vchan = vchan(part1);
if(isfield(prof,'rcalc'))
    prof.rcalc = rcalc(part1,:);
end
if(isfield(prof,'robs1'))
    prof.robs1 = robs1(part1,:);
end
if(isfield(prof,'calflag'))
    prof.calflag = calflag(part1,:);
end
if isempty(z)
  %hattr = set_attr(hattr,'rtpfile',[rtp_outfile '_1']);
end
rtpwrite(tmpfile1,head,hattr,prof,pattr);

% PART 2
head.nchan = length(part2);
head.ichan = part2;
head.vchan = vchan(part2);
if(isfield(prof,'rcalc'))
    prof.rcalc = rcalc(part2,:);
end
if(isfield(prof,'robs1'))
    prof.robs1 = robs1(part2,:);
end
if(isfield(prof,'calflag'))
    prof.calflag = calflag(part2,:);
end
if isempty(z)
  %hattr = set_attr(hattr,'rtpfile',[rtp_outfile '_2']);
end
rtpwrite(tmpfile2,head,hattr,prof,pattr);

% if we have not had any errors yet, lets start moving these into place
movefile(tmpfile1,[rtp_outfile '_1' z]);
movefile(tmpfile2,[rtp_outfile '_2' z]);

file_names = {[rtp_outfile '_1' z],[rtp_outfile '_2' z]};

%%% end of function %%%
