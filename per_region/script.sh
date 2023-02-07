#!/bin/bash 

# Docker image
IMAGE='fredmoser/accessmod:latest'

# Inputs
OUTPUT_DIR=/$1
PROJECT_FILE=/$1/project.am5p
R_SCRIPT_FILE='./get_regions.R'
CONFIG_FILE=/$1/config.json

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
docker run \
  --rm \
  -v $OUTPUT_DIR:/batch/out \
  -v $PROJECT_FILE:/batch/project.am5p \
  -v $CONFIG_FILE:/batch/config.json \
  -v $(pwd)/$R_SCRIPT_FILE:/batch/script.R \
  $IMAGE \
  Rscript /batch/script.R $2


