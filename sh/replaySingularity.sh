#!/bin/bash

# Load modules
# ml GCC/9.3.0 Singularity/3.7.3-Go-1.14

# Passed parameters
PARAM=("${@}")
INPUT_DIR=${PARAM[1]}
RUN_DIR=${PARAM[3]}
SPLIT=${PARAM[6]}
OUTPUT_DIR=${PARAM[4]}
IMAGE=${PARAM[2]}

# Not necessary anymore. It allows to write directly with --compat (?)
# Make a tempdir for Accessmod DB
TEMP_DIR=$(mktemp -d)

# Is this a regular job or a job array
if [[ -n $SLURM_ARRAY_TASK_ID ]]
then
  JOB_ID=$SLURM_ARRAY_TASK_ID
  # Get the ID so in the R script we can know either the region index or the travel time
  PARAM[29]="$JOB_ID"
fi

# # Make temporary directory for GRASS database
mkdir -p "$TEMP_DIR/dbgrass"
mkdir -p "$TEMP_DIR/cache"
mkdir -p "$TEMP_DIR/logs"
# Directory to be binded
DATA_DIR="$TEMP_DIR"

# Other dir/files to be binded
PROJECT_FILE="$INPUT_DIR/project.am5p"
R_SCRIPT_FILE="$RUN_DIR/R/replay.R"
CONFIG_FILE="$INPUT_DIR/config.json"
FUNCTIONS_SCRIPT_FILE="$RUN_DIR/R/functions.R"

ARGUMENTS=$(printf "%q " "${PARAM[@]}")

# If split we need to bind the regions.json file as well
if [[ $SPLIT == "true" ]]
then
  REGION_JSON_FILE=${PARAM[28]}
  # Run image with binded inputs and launch R script
  # Has been removed: # -B $DATA_DIR:/data \
  echo "Start processing AccessMod Job"
  srun singularity run \
    -B $OUTPUT_DIR:/batch/out \
    -B $PROJECT_FILE:/batch/project.am5p \
    -B $CONFIG_FILE:/batch/config.json \
    -B $REGION_JSON_FILE:/batch/regions.json \
    -B $FUNCTIONS_SCRIPT_FILE:/batch/functions.R \
    -B $R_SCRIPT_FILE:/batch/replay.R \
    -B $DATA_DIR:/data \
    --pwd /app \
    $IMAGE Rscript /batch/replay.R "${PARAM[@]}"
else
  echo "Start processing AccessMod Job"
  srun singularity run \
  -B $OUTPUT_DIR:/batch/out \
  -B $PROJECT_FILE:/batch/project.am5p \
  -B $CONFIG_FILE:/batch/config.json \
  -B $FUNCTIONS_SCRIPT_FILE:/batch/functions.R \
  -B $R_SCRIPT_FILE:/batch/replay.R \
  -B $DATA_DIR:/data \
  --pwd /app \
  $IMAGE Rscript /batch/replay.R "${PARAM[@]}"
fi
