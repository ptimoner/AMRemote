#!/bin/bash

#SBATCH --job-name=test
#SBATCH --time=60
#SBATCH --partition=shared-cpu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=300000
#SBATCH --mail-type=ALL

# Load modules
ml GCC/9.3.0 Singularity/3.7.3-Go-1.14

# Singularity image
IMAGE=$2

# Array values come from main_hpc.sh (sbatch -a $SERVICES)
REGION=$SLURM_ARRAY_TASK_ID

# New directories for binding data folder (bypass denied access for writing) and out directory
mkdir -p /$1/data$REGION/dbgrass
mkdir -p /$1/data$REGION/cache
mkdir -p /$1/data$REGION/logs
mkdir -p /$1/out/$REGION

# Inputs
OUTPUT_DIR=/$1/out/$REGION
PROJECT_FILE=/$1/project.am5p
R_SCRIPT_FILE='./script_hpc.R'
CONFIG_FILE=/$1/config.json
INPUT_FILE=/$1/inputs.json
DATA_DIR=/$1/data$REGION

echo "Start processing AccessMod Job"

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
check_file "$INPUT_FILE"
check_file "$DATA_DIR"

# Run image with binded inputs and launch R script
singularity run \
  -B $OUTPUT_DIR:/batch/out \
  -B $PROJECT_FILE:/batch/project.am5p \
  -B $CONFIG_FILE:/batch/config.json \
  -B $INPUT_FILE:/batch/inputs.json \
  -B $R_SCRIPT_FILE:/batch/script_hpc.R \
  -B $DATA_DIR:/data \
  --pwd /app \
  $IMAGE \
  Rscript /batch/script_hpc.R $REGION

# Remove data (dbgrass, logs, cache)
rm -r /$1/data$REGION
