% create_rtp.m

addpath ~/Work/Rtp
addpath /asl/matlib/aslutil

% Create list of files to process

datadir1 = '/asl/data/cris/ccast/sdr60_hr/2013/239';
datadir2 = '/asl/data/cris/ccast/sdr60_hr/2013/240';

clear a a1 a2

a1 = dir(fullfile(datadir1,'SDR*.mat'));
a2 = dir(fullfile(datadir2,'SDR*.mat'));

for i=1:length(a1)
   a1(i).name = fullfile(datadir1,a1(i).name);
   a2(i).name = fullfile(datadir2,a2(i).name);
end

% Combine file info into single structure
a = [a1; a2];

n = length(a);
nguard = 4;

for i=87
   [head, hattr, prof, pattr] = ccast2rtp(a(i).name, nguard);
end

[prof,head]=fill_ecmwf(prof,head);
head.pfields = 5;

simplemap(prof.rlat,prof.rlon,prof.stemp,0.5);

[head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);
[head,hattr,prof,pattr]=rtpadd_emis_DanZhou(head,hattr,prof,pattr);
rtpwrite('aug27_gran87.rtp',head,hattr,prof,pattr)

%from breno_rtp_prod/
% by pass, saved output
%[r888,klayers,sarta]=cris888_sarta_wrapper_bc('aug27_gran87.rtp',4);

load iasi_sarta_out

[f_cris, rad_cris] = iasi_to_cris888_grid(rad_iasi, atype, crisband_fstart, crisband_df, crisband_fend); 

[c ia ib]=intersect(f_cris,head.vchan);

% Then, redo rtp using rad_cris(ia), everything else in prof use ib to subset


% Then just put rad_cris into prof.rcalc and f_cris into head.vchan
% should also form head.ichan

% see compute_clear_wrapper.m in breno extra_routines
%rtpwrite('test1.rtp',head,hattr,prof,pattr);

% Now run klayers
% Followed by sarta iasi