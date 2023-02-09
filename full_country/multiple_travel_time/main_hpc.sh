#!/bin/bash
# $2 parameter correspond to the path to the singularity AccessMod image
# to download the image e.g. singularity pull accessmod.sif docker://fredmoser/accessmod:5.8.0
# CHECK parameters
mkdir -p $1/out/slum_reports
mkdir -p $1/out/results

TRAVELTIMES=$(cat inputs.json | jq -r '.travelTimes | join(",")')
# echo 'Submitting main analyses (job array)...'
echo $TRAVELTIMES
# sbatch -a $TRAVELTIMES -o $1/out/slum_reports/%a_%A.out script_hpc.sh $1 $2
