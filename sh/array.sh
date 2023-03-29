#!/bin/bash

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
JOB_NAME=${PARAM[14]}

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
  JOB_REGIONS_ID=${PARAM[15]}
  # Wait for the first job to complete before continuing (safety)
  scontrol wait "$JOB_REGIONS_ID"
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
    CODE_ID=""
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
        CODE_ID+="$(printf "%s%s" "$i_NEW" "$j_NEW"),"
      done
    done
    # Remove the trailing comma from the output string
    CODE_ID=${CODE_ID::-1}
  else
  # If only split
  CODE_ID=$REGIONS
  fi
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
      CODE_ID="${MAX_TRAVEL_TIME// /,}"
    else
      CODE_ID=""
    fi
  else
    CODE_ID=""
  fi
fi

# Get the ID of this second job to be sure to run the last sbatch after this one is finished
JOB_ARRAY_ID=$(squeue -h -u $USER -o %i -n $JOB_NAME)

# Make random jobname (so we avoid conflict if we run multiple analysis at the same time)
JOB_NAME="3_$(tr -dc 'a-zA-Z' < /dev/urandom | head -c 5)"

# Regular job
if [[ -z "$CODE_ID" ]]
then
  sbatch --dependency=afterok:${JOB_ARRAY_ID} --output "$OUTPUT_DIR/slum_reports/replay.out" --job-name="$JOB_NAME" "$RUN_DIR/sh/replaySingularity.sh" "${PARAM[@]}"
else
  # Job array
  # Create a table where we have indices from 1 to ...  and our CODE_ID (that contains the information of regions and/or travel time)
  # Necessary because we have a maximum index for job array
  # How many jobs ?
  N=$(echo "$CODE_ID" | tr ',' ' ' | wc -w)
  # Array from 1 to N
  ONETON=$(echo $(seq 1 $N))
  read -r -a SEQUENCE <<< "$(echo $ONETON)"
  INDICES=$(echo "$ONETON" | sed 's/ /,/g')
  # We create an array with our CODE_ID
  IFS="," read -r -a IDS <<< "$(echo "$CODE_ID")"
  # We create a table
  # Iterate over the arrays and write each pair to a file
  for i in "${!SEQUENCE[@]}"
  do
    echo "${SEQUENCE[i]} ${IDS[i]}" >> "$OUTPUT_DIR/ids.txt"
  done
  sbatch --dependency=afterok:${JOB_ARRAY_ID} --array=$INDICES --output="$OUTPUT_DIR/slum_reports/replay_%a_%A.out" --job-name="$JOB_NAME" "$RUN_DIR/sh/replaySingularity.sh" "${PARAM[@]}"
fi