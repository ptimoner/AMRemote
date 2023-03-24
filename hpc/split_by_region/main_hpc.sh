#!/bin/bash
# $1 parameter corresponds to input folder path
# $2 parameter corresponds to the path to the singularity AccessMod image
# to download the image e.g. singularity pull accessmod.sif docker://fredmoser/accessmod:5.8.0
# $3 parameter corresponds to the name of the column in the facility shapefile that refers to the region
if [[ $# -ne 3 ]]; then
    echo "Illegal number of parameters" >&2
    exit 2
fi

echo 'Getting regions: please wait until the second batch job is submitted...'
mkdir -p $1/out/slum_reports
mkdir -p $1/out/results

# Get location of the main script
BASH_SCRIPT_DIR=$(echo $0 | sed 's/main_hpc.sh//g')

sbatch -W -o $1/out/slum_reports/regions_%j.out ${BASH_SCRIPT_DIR}script_hpc_get_regions.sh $1 $2 $3 $BASH_SCRIPT_DIR
REGIONS=$(cat $1/inputs.json | jq -r '.index | join(",")')
# echo $REGIONS
# REGIONS=$(echo 2)

# echo 'Submitting main analyses (job array)...'
sbatch -a $REGIONS -o $1/out/slum_reports/%a_%A.out script_hpc.sh $1 $2 $BASH_SCRIPT_DIR
