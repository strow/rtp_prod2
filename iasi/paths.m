% path definitions for rtp_prod2/iasi/ procedures

% Check that we are in the correct place.
whereami = pwd;
junk = findstr(whereami,'/rtp_prod2/iasi');
if(isempty(junk)) fprintf(1,'Error: you need to be in rtp_prod2/iasi\n'); return; end
if(~strcmp(whereami(junk:end),'/rtp_prod2/iasi'))
  fprintf(1,'Error: you need to be in rtp_prod2/iasi/run\n'); return; end

% establish root of this path which is valid:
MYROOT = whereami(1:junk);

addpath([MYROOT 'rtp_prod2/grib'])                  % fill_ecmwf.m fill_era.m
addpath([MYROOT 'rtp_prod2/emis'])                  % rtp_add_emis_single.m
addpath([MYROOT 'rtp_prod2/util'])                  % seq_match.m, rtpadd_usgs_10dem.m
addpath([MYROOT 'rtp_prod2/iasi'])
addpath([MYROOT 'rtp_prod2/iasi/readers'])           % read_eps*.m
addpath /asl/matlib/rtptools                        % set_attr.m, rtpwrite_12.m etc
addpath /asl/matlib/aslutil/                        % mktemp.m unlink.m

% now go to the run/ sub-directory for the rest of the session.
cd([whereami '/run']);
