#!/bin/bash

#SBATCH --job-name=test
#SBATCH --time=60
#SBATCH --partition=public-cpu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10000
#SBATCH --mail-type=ALL

# Load modules
ml GCC/9.3.0 Singularity/3.7.3-Go-1.14

# Singularity image
IMAGE=$2

# New directories for binding data folder (bypass denied access for writing) and out directory
mkdir -p $1/dataTemp/dbgrass
mkdir -p $1/dataTemp/cache
mkdir -p $1/dataTemp/logs

# Inputs
OUTPUT_DIR=$1
PROJECT_FILE=$1/project.am5p
R_SCRIPT_FILE='./get_regions.R'
CONFIG_FILE=$1/config.json
DATA_DIR=$1/dataTemp

echo "Start collecting information on regions"

check_file()
{
  if [ ! -e "$1" ]; 
  then 
    echo "Missing file/dir: $1";
    exit 1;
  fi
}

check_file "$OUTPUT_DIR"
check_file "$PROJECT_FILE"
check_file "$R_SCRIPT_FILE"
check_file "$CONFIG_FILE"
check_file "$DATA_DIR"

# Run image with binded inputs and launch R script
singularity run \
  -B $OUTPUT_DIR:/batch/out \
  -B $PROJECT_FILE:/batch/project.am5p \
  -B $CONFIG_FILE:/batch/config.json \
  -B $R_SCRIPT_FILE:/batch/get_regions.R \
  -B $DATA_DIR:/data \
  --pwd /app \
  $IMAGE \
  Rscript /batch/get_regions.R $3

# Remove data (dbgrass, logs, cache)
rm -r /$1/dataTemp
