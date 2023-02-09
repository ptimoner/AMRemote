#!/bin/bash
# $2 parameter correspond to the path to the singularity AccessMod image
# to download the image e.g. singularity pull accessmod.sif docker://fredmoser/accessmod:5.8.0
# CHECK parameters
mkdir -p $1/out/slum_reports
mkdir -p $1/out/results

# echo 'Submitting main analyses (job array)...'
sbatch -o $1/out/slum_reports/%a_%A.out script_hpc.sh $1 $2 
