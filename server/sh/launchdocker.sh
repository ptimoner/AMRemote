#!/bin/bash

PARAM=("${@}")

# Parameters
INPUT_DIR=${PARAM[0]}
IMAGE=${PARAM[1]}
RUN_DIR=${PARAM[2]}
multiTT=${PARAM[3]}
inputTravelTime=${PARAM[4]}
split=${PARAM[5]}
adminCol=${PARAM[6]}
zonalStat=${PARAM[7]}
inputPop=${PARAM[8]}
inputZone=${PARAM[9]}
zoneIDField=${PARAM[10]}
zoneLabelField=${PARAM[11]}

PARAM=("$multiTT" "$inputTravelTime" "$split" "$adminCol" "$zonalStat" "$inputPop" "$inputZone" "$zoneIDField" "$zoneLabelField")

# As the container will be run as a non-root user, we need to bind the /data folder
# If not, we don't have the right to access it (by default volume mounted to the root)
# Get the current date and time in the format YYYY-MM-DD-HH-MM-SS
timestamp=$(date +%Y-%m-%d-%H-%M-%S)
mkdir -p "$INPUT_DIR/out/$timestamp"
mkdir -p "$INPUT_DIR/AMdata/logs"
mkdir -p "$INPUT_DIR/AMdata/cache"
mkdir -p "$INPUT_DIR/AMdata/dbgrass"

# Files to be binded
OUTPUT_DIR=$INPUT_DIR/out
DATA_DIR=$INPUT_DIR/AMdata
PROJECT_FILE=$INPUT_DIR/project.am5p
R_SCRIPT_FILE=$RUN_DIR/R/replay.R
CONFIG_FILE=$INPUT_DIR/config.json

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
  -v $R_SCRIPT_FILE:/batch/script.R \
  $IMAGE \
  Rscript /batch/script.R --args "${PARAM[@]}"
