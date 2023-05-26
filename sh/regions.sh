#!/bin/bash

# Load modules
ml GCC/9.3.0 Singularity/3.7.3-Go-1.14

# Passed parameters
PARAM=("${@}")

# Parameters
INPUT_DIR=${PARAM[1]}
IMAGE=${PARAM[2]}
RUN_DIR=${PARAM[3]}
OUTPUT_DIR=${PARAM[4]}
ADMIN_COL=${PARAM[7]}
JOB_NAME=${PARAM[26]}
PP_NAME=${PARAM[14]}
PP_TIME=${PARAM[15]}
PP_NTASKS=${PARAM[16]}
PP_CPUS_TASK=${PARAM[17]}
PP_MEM=${PARAM[18]}
PP_MAIL=${PARAM[19]}

# As the container will be run as a non-root user, we need to bind the /data folder
# If not, we don't have the right to access it (by default volume mounted to the root)

# Make a tempdir for Accessmod DB
TEMP_DIR=$(mktemp -d)

mkdir -p "$TEMP_DIR/logs"
mkdir -p "$TEMP_DIR/cache"
mkdir -p "$TEMP_DIR/dbgrass"

# Files to be binded
DATA_DIR="$TEMP_DIR"
PROJECT_FILE="$INPUT_DIR/project.am5p"
R_SCRIPT_FILE="$RUN_DIR/R/regions.R"
CONFIG_FILE="$INPUT_DIR/config.json"
FUNCTIONS_SCRIPT_FILE="$RUN_DIR/R/functions.R"

# Run image with binded inputs and launch R script with ADMIN_COL parameter
singularity run \
  -B $OUTPUT_DIR:/batch/out \
  -B $PROJECT_FILE:/batch/project.am5p \
  -B $CONFIG_FILE:/batch/config.json \
  -B $R_SCRIPT_FILE:/batch/regions.R \
  -B $FUNCTIONS_SCRIPT_FILE:/batch/functions.R \
  -B $DATA_DIR:/data \
  --pwd /app \
  $IMAGE \
  Rscript /batch/regions.R "$ADMIN_COL"

# Get the ID of this first job
JOB_REGIONS_ID=$(squeue -h -u $USER -o %i -n $JOB_NAME)

# jobID parameter
PARAM[27]="$JOB_REGIONS_ID"

# Make random jobname (so we avoid conflict when accessing job id using the name, when we run multiple analysis at the same time)
JOB_NAME="2_$(tr -dc 'a-zA-Z' < /dev/urandom | head -c 5)"
PARAM[26]=$JOB_NAME

# Submit the second job (array.sh to prepare the inputs and run singularity for the analysis) with a dependency on the first job
sbatch \
  --dependency=afterok:${JOB_REGIONS_ID} \
  --output="$OUTPUT_DIR/slum_reports/array.out" \
  --job-name="$JOB_NAME" \
  --partition="$PP_NAME" \
  --time="$PP_TIME" \
  --ntasks="$PP_NTASKS" \
  --cpus-per-task="$PP_CPUS_TASK" \
  --mem-per-cpu="$PP_MEM" \
  --mail-type="$PP_MAIL" \
  "$RUN_DIR/sh/array.sh" "${PARAM[@]}"