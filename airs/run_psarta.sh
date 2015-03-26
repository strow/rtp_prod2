#!/bin/bash

# run_psarta SCRATCHPATH SNODEID SARTAPATH
# 
# parallelizes sarta run by executing 8 background sarta processes
# operating on rtp subset files as input. subset files are produced
# outside this routine and stored in /tmp or /scratch space (as
# appropriate). The path to these input files and the cluster relative
# node ID are passed in to allow access to the input files and
# creation of the corresponding output files. A path to the sarta
# executable to be used must also be specified in the call to this script.

SCRATCHPATH=$1

SNODEID=$2

SARTAPATH=$3

# loop over input files
for i in {1..8}; do
    # build input file name
    finput=${SCRATCHPATH}/psarta_${SNODEID}_${i}_in.rtp
    # build output filename
    foutput=${SCRATCHPATH}/psarta_${SNODEID}_${i}_out.rtp
    # run sarta
    $SARTAPATH fin=$finput fout=$foutput > ${SCRATCHPATH}/sartaout_${i}.txt &   
done
wait


