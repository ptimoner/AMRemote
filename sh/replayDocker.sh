#!/bin/bash

PARAM=("${@}")

# Parameters
INPUT_DIR=${PARAM[1]}
IMAGE=${PARAM[2]}
RUN_DIR=${PARAM[3]}
OUTPUT_DIR=${PARAM[4]}

# As the container will be run as a non-root user, we need to bind the /data folder
# If not, we don't have the right to access it (by default volume mounted to the root)
# Get the current date and time in the format YYYY-MM-DD-HH-MM-SS
mkdir -p "$INPUT_DIR/AMdata/logs"
mkdir -p "$INPUT_DIR/AMdata/cache"
mkdir -p "$INPUT_DIR/AMdata/dbgrass"

# Files to be binded
DATA_DIR="$INPUT_DIR/AMdata"
PROJECT_FILE="$INPUT_DIR/project.am5p"
REPLAY_SCRIPT_FILE="$RUN_DIR/R/replayDocker.R"
FUNCTIONS_SCRIPT_FILE="$RUN_DIR/R/functions.R"
CONFIG_FILE="$INPUT_DIR/config.json"

echo "Start processing AccessMod Job"
# Run docker with mounted inputs and launch the R script
# --rm clean up the container
# --user so the docker container is run as a non-root user (to keep the rights on the outputs)
docker run \
  --rm \
  --user $(id -u):$(id -g) \
  -v $DATA_DIR:/data \
  -v $OUTPUT_DIR:/batch/out \
  -v $PROJECT_FILE:/batch/project.am5p \
  -v $CONFIG_FILE:/batch/config.json \
  -v $REPLAY_SCRIPT_FILE:/batch/replayDocker.R \
  -v $FUNCTIONS_SCRIPT_FILE:/batch/functions.R \
  $IMAGE \
  Rscript /batch/replayDocker.R "${PARAM[@]}"
