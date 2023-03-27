#!/bin/bash

#SBATCH --job-name=array
#SBATCH --time=60:00
#SBATCH --partition=shared-cpu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10000
#SBATCH --mail-type=NONE

# Passed parameters
PARAM=("${@}")
RUN_DIR=${PARAM[3]}
MAX_TRAVEL_TIME=${PARAM[5]}
SPLIT=${PARAM[6]}
OUTPUT_DIR=${PARAM[4]}
ZONAL_STAT=${PARAM[8]}

# Do we have multiple travel times (in specific cases we would run a job array)
if [ ${#MAX_TRAVEL_TIME} -gt 1 ]
then
    MULTI_TRAVEL_TIMES=true
else
    MULTI_TRAVEL_TIMES=false
fi

# Do we need an array (multiple travel times, split by region, both) ?
# Check if split by region
if [ $SPLIT == "true" ]
then
  JOB_REGIONS_ID=${PARAM[13]}
  # Wait for the first job to complete before continuing
  scontrol wait jobid="$JOB_REGIONS_ID"
  # Path to the created regions.json file (with get_regions.R)
  REGION_JSON_FILE="$OUTPUT_DIR/regions.json"
  # Get region indices
  REGIONS=$(cat "$REGION_JSON_FILE" | jq -r '.index | join(",")')
  # Pass all parameters + JSON file path (required in R script)
  PARAM+=("$REGION_JSON_FILE")
  if [[ $MULTI_TRAVEL_TIMES == "true" ]]
  then
    # We want to be able to separate then the time and the region index
    # Must be numerical for sbatch array
    # Split the input variables into arrays
    TIME_ARRAY=($MAX_TRAVEL_TIME)
    REGION_ARRAY=(${REGIONS//,/ })
    # Initialize the output variable
    ARRAY_IND=""
    ADD=10000
    # Loop over each element of a and b
    for i in "${TIME_ARRAY[@]}"
    do
      for j in "${REGION_ARRAY[@]}"
      do
        # Add the constant value to the current element
        i_NEW=$((i + ADD))
        j_NEW=$((j + ADD))
        # Concatenate the two elements into a new string
        ARRAY_IND+="$(printf "%s%s" "$i_NEW" "$j_NEW"),"
      done
    done
    # Remove the trailing comma from the output string
    ARRAY_IND=${ARRAY_IND::-1}
  else
  # If only split
  ARRAY_IND=$REGIONS
else
# If no split by region
# To maintain same number of parameters that are passed through the different scripts
  REGION_JSON_FILE=""
  PARAM+=("$REGION_JSON_FILE")
  if [[ MULTI_TRAVEL_TIMES == "true" ]]
  then
    if [[ ZONAL_STAT == "false" ]]
    then
    # ID will be travel times
      ARRAY_ID="${MAX_TRAVEL_TIME// /,}"
    else
      ARRAY_ID=""
    fi
  else
    ARRAY_ID=""
  fi
fi

# Get the ID of this second job to be sure to run the last sbatch after this one is finished
JOB_ARRAY_ID=$(squeue -h -u $USER -o %i -n array)

# Regular job
if [[ -z "$ARRAY_ID" ]]
then
  sbatch --dependency=afterok:${JOB_ARRAY_ID} --output "$OUTPUT_DIR/slum_reports/replay.out" replaySingularity.sh "${PARAM[@]}"
else
  # Job array
  sbatch --dependency=afterok:${JOB_ARRAY_ID} --array=$JOB_ARRAY_ID --output "$OUTPUT_DIR/slum_reports/%a_%A.out" replaySingularity.sh "${PARAM[@]}"
fi