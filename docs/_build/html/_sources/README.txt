Readme
======

Introduction
------------

``rtp-prod`` creates blah blah

In order to run kcmix, the user also needs to install/download

1) hdf packages

2) rtp package, which is our native file format for storing
   atmospheric geophysical variables and instrument view geometry
   parameters, needed for RT calculations

3) klayers package, which takes in a LEVELS rtp file and produces a LAYERS 
   average rtp file, needed for RT calculations

Main Top Level Routines
-----------------------

This is all junk filler.

kcrad
    Radiative transfer top-level wrapper, manages defaults and
    loops on chunks, calling kcmix2, contcalc, and rtchunk

rtchunk
    Radiative transfer calc's in 10\ :sup:`4`\ point chunks, including
    reflected solar and basic reflected thermal

kcmix2
    Calculates 25 1/cm chunks of mixed absorptions for a
    supplied profile, from tabulated compressed absorptions

kcmix100
    Version of kcmix that assumes a 100-layer input profile
    with the same layers as the reference profiles

contcalc
    Continuum calculation from kcarta tabulated values

Documentation
-------------

Documentation is available in the ``docs`` subdirectory, and is fairly
up-to-date. 
