.. rtp-prod documentation master file, created by
   sphinx-quickstart on Wed Dec 31 10:41:06 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

rtp-prod Documentation
======================

Overview

The rtp-prod system takes hyperspectral satellite sounder radiances
and matches them to gridded numerical weather model analysis (or
re-analysis) data.  This provides a quite accurate estimate of the
atmospheric state (temperature, humidity and ozone profiles, surface
temperature) for each sounder observations.

The profile data is supplemented with estimates for the land surface
emissivity (using D. Zhou's IASI emissivity database, ref needed), and
using xxx (ref needed) for the sea surface emissivity. 

Three sounders are presently supported: (1) AIRS on EOS-AQUA, (2)
IASI-1 on METOP-I, and (3) CrIS on Soumi-NPP.

The output of rtp-prod is an rtp file (hyperlink this to rtp docs),
that contains a list of observations and associated profiles.

Presently this code is "working" for CrIS (no clear subsetting) and
for the AIRS AIRXBCAL clear subset product that can be downloaded
from the NASA GSFC DAAC.

More needed ...

Contents:

.. toctree::
    :maxdepth: 3

    rtp-prod.rst

    

    
