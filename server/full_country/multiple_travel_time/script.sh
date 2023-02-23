#!/bin/bash

# Docker image
IMAGE=$2

# Output folder
mkdir -p /$1/out

# Inputs
OUTPUT_DIR=/$1/out
PROJECT_FILE=/$1/project.am5p
R_SCRIPT_FILE='./script.R'
CONFIG_FILE=/$1/config.json
INPUT_FILE=/$1/inputs.json

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

# Run docker with mounted inputs and launch the R script
docker run \
  --rm \
  -v $OUTPUT_DIR:/batch/out \
  -v $PROJECT_FILE:/batch/project.am5p \
  -v $CONFIG_FILE:/batch/config.json \
  -v $INPUT_FILE:/batch/inputs.json \
  -v $(pwd)/$R_SCRIPT_FILE:/batch/script.R \
  $IMAGE \
  Rscript /batch/script.R
