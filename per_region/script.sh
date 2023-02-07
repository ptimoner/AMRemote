#!/bin/bash 

# Docker image
IMAGE='fredmoser/accessmod:latest'

# Inputs
OUTPUT_DIR='./out'
PROJECT_FILE='./project.am5p'
R_SCRIPT_FILE='./script.R'
CONFIG_FILE='./config.json'

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
  -v $(pwd)/$OUTPUT_DIR:/batch/out \
  -v $(pwd)/$PROJECT_FILE:/batch/project.am5p \
  -v $(pwd)/$CONFIG_FILE:/batch/config.json \
  -v $(pwd)/$R_SCRIPT_FILE:/batch/script.R \
  $IMAGE \
  Rscript /batch/script.R $1


