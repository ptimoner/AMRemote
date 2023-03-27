#!/bin/bash

#SBATCH --job-name=replay
#SBATCH --time=4-00:00:00
#SBATCH --partition=public-cpu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10000
#SBATCH --mail-type=ALL


# Load modules
ml GCC/9.3.0 Singularity/3.7.3-Go-1.14

# Passed parameters
PARAM=("${@}")
INPUT_DIR=${PARAM[1]}
RUN_DIR=${PARAM[3]}
SPLIT=${PARAM[6]}
OUTPUT_DIR=${PARAM[4]}
IMAGE=${PARAM[2]}
echo $IMAGE


# Is this a regular job or a job array
if [[ -n $SLURM_ARRAY_TASK_ID ]]
then
  JOB_ID=$SLURM_ARRAY_TASK_ID
  # Get the ID so in the R script we can know either the region index or the travel time
  PARAM+=("$JOB_ID") 
  # New directories for binding data folder (bypass denied access for writing) and out directory
  # We need a database per job to avoid conflict (in the end of this script we remove these folders)
  mkdir -p "$INPUT_DIR/AMdata/temp/$JOB_ID/dbgrass"
  mkdir -p "$INPUT_DIR/AMdata/temp/$JOB_ID/cache"
  mkdir -p "$INPUT_DIR/AMdata/temp/$JOB_ID/logs"
  # Directory to be binded
  DATA_DIR="$INPUT_DIR/AMdata/temp/$JOB_ID"
else
  mkdir -p "$INPUT_DIR/AMdata/dbgrass"
  mkdir -p "$INPUT_DIR/AMdata/cache"
  mkdir -p "$INPUT_DIR/AMdata/logs"
  DATA_DIR="$INPUT_DIR/AMdata"
  JOB_ID=""
  # So we we have the same number of parameters that are passed to the R script
  PARAM+=("$JOB_ID")
fi

# Other dir/files to be binded
PROJECT_FILE="$INPUT_DIR/project.am5p"
R_SCRIPT_FILE="$RUN_DIR/R/replay.R"
CONFIG_FILE="$INPUT_DIR/config.json"

# If split we need to bind the regions.json file as well
if [[ $SPLIT == "true" ]]
then
  REGION_JSON_FILE=${PARAM[14]}
  # Run image with binded inputs and launch R script
  echo "Start processing AccessMod Job"
  singularity run \
    -B $OUTPUT_DIR:/batch/out \
    -B $PROJECT_FILE:/batch/project.am5p \
    -B $CONFIG_FILE:/batch/config.json \
    -B $REGION_JSON_FILE:/batch/regions.json \
    -B $R_SCRIPT_FILE:/batch/replay.R \
    -B $DATA_DIR:/data \
    --pwd /app \
    $IMAGE \
    Rscript /batch/replay.R "${PARAM[@]}"
else
  echo "Start processing AccessMod Job"
  singularity run \
  -B $OUTPUT_DIR:/batch/out \
  -B $PROJECT_FILE:/batch/project.am5p \
  -B $CONFIG_FILE:/batch/config.json \
  -B $R_SCRIPT_FILE:/batch/replay.R \
  -B $DATA_DIR:/data \
  --pwd /app \
  $IMAGE \
  Rscript /batch/replay.R "${PARAM[@]}"
fi

# Remove duplicated data (dbgrass, logs, cache)
if [[ -n $SLURM_ARRAY_TASK_ID ]]
then
  rm -r "$INPUT_DIR/AMdata/temp/"
fi
