#!/bin/bash
# $2 parameter correspond to the path to the singularity AccessMod image
# to download the image e.g. singularity pull accessmod.sif docker://fredmoser/accessmod:5.8.0
echo 'Getting regions: please wait...'
mkdir -p slurm_reports
sbatch -W -o ./slurm_reports/regions.out script_hpc_get_regions.sh $1 $2 $3
REGIONS=$(cat $1/inputs.json | jq -r '.index | join(",")')
echo $REGIONS
# REGIONS=$(echo 2)

# echo 'Submitting main analyses (job array)...'
sbatch -a $REGIONS -o ./slurm_reports/%a_%A.out script_hpc.sh $1 $2
