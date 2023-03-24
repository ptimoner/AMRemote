#!/bin/bash

# Docker image
IMAGE=$2

# Output folder
# As the container will be run as a non-root user, we need to bind the /data folder
# If not, we don't have the right to access it (by default volume mounted to the root)
mkdir -p $1/out
mkdir -p $1/AMdata/logs
mkdir -p $1/AMdata/cache
mkdir -p $1/AMdata/dbgrass

# Get the location of this script
BASH_SCRIPT_DIR=$(echo $0 | sed 's/script.sh//g')

# Inputs
OUTPUT_DIR=$1/out
DATA_DIR=$1/AMdata
PROJECT_FILE=$1/project.am5p
R_SCRIPT_FILE=${BASH_SCRIPT_DIR}script.R
CONFIG_FILE=$1/config.json

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
  Rscript /batch/script.R
