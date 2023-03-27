#!/bin/bash

#SBATCH --job-name=regions
#SBATCH --time=60:00
#SBATCH --partition=shared-cpu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10000
#SBATCH --mail-type=NONE

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

# As the container will be run as a non-root user, we need to bind the /data folder
# If not, we don't have the right to access it (by default volume mounted to the root)
mkdir -p "$INPUT_DIR/AMdata/logs"
mkdir -p "$INPUT_DIR/AMdata/cache"
mkdir -p "$INPUT_DIR/AMdata/dbgrass"

# Files to be binded
DATA_DIR="$INPUT_DIR/AMdata"
PROJECT_FILE="$INPUT_DIR/project.am5p"
R_SCRIPT_FILE="$RUN_DIR/R/regions.R"
CONFIG_FILE="$INPUT_DIR/config.json"

# Run image with binded inputs and launch R script with ADMIN_COL parameter
singularity run \
  -B $OUTPUT_DIR:/batch/out \
  -B $PROJECT_FILE:/batch/project.am5p \
  -B $CONFIG_FILE:/batch/config.json \
  -B $R_SCRIPT_FILE:/batch/regions.R \
  -B $DATA_DIR:/data \
  --pwd /app \
  $IMAGE \
  Rscript /batch/regions.R "$ADMIN_COL"

# Get the ID of this first job
JOB_REGIONS_ID=$(squeue -h -u $USER -o %i -n regions)

# Pass all parameters + jobID
PARAM+=("$JOB_REGIONS_ID")

# Submit the second job (array.sh to prepare the inputs and run singularity for the analysis) with a dependency on the first job
sbatch --dependency=afterok:${JOB_REGIONS_ID} --output "$OUTPUT_DIR/slum_reports/array.out" "$RUN_DIR/sh/array.sh" "${PARAM[@]}"
