#!/bin/bash
# $1 parameter corresponds to input folder path
# $2 parameter corresponds to the path to the singularity AccessMod image
# to download the image e.g. singularity pull accessmod.sif docker://fredmoser/accessmod:5.8.0
# CHECK parameters
if [[ $# -ne 2 ]]; then
    echo "Illegal number of parameters" >&2
    exit 2
fi

mkdir -p $1/out/slum_reports
mkdir -p $1/out/results

# Get location of the main script
BASH_SCRIPT_DIR=$(echo $0 | sed 's/main_hpc.sh//g')

TRAVELTIMES=$(cat inputs.json | jq -r '.travelTimes | join(",")')
# echo 'Submitting main analyses (job array)...'
sbatch -a $TRAVELTIMES -o $1/out/slum_reports/%a_%A.out script_hpc.sh $1 $2 $BASH_SCRIPT_DIR
