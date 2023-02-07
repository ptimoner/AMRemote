#!/bin/bash
REGIONS=$(cat $1/inputs.json | jq -r '.index | join(",")')
echo $REGIONS
# $1 parameter correspond to the path to the singularity AccessMod image
# to download the image e.g. singularity pull accessmod.sif docker://fredmoser/accessmod:5.8.0
# mkdir -p slurm_reports
# sbatch -a $REGIONS -o ./slurm_reports/%a_%A.out script_hpc.sh $1 $2
