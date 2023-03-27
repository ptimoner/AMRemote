#!/bin/bash

# Define the function to check if a variable is a boolean ()
function is_boolean {
  # Define the regular expression for matching boolean values
  BOOLEAN_REGEX="^(true|false)$"
  # Check if the input variable matches the boolean regex
  if [[ ! $1 =~ $BOOLEAN_REGEX ]]
  then
    echo "$1 is not a boolean (true/false)."
    exit 2
  fi
}


# Is slurm management available (cluster)
if command -v sinfo >/dev/null 2>&1
  then
  echo "Slurm Workload Manager is installed"
  echo "'nohup' argument will be ignored"
  HPC=true
else
  HPC=false
  # Do we want to be able to close the terminal without killing the process
  NOHUP=$(jq -r '.nohup' inputs.json)
  is_boolean "$NOHUP"
fi

# Get AccessMod image
IMAGE=$(jq -r '.AccessModImage' inputs.json)
if ! echo "$IMAGE" | grep -q "\.sif" && [[ $HPC == "true" ]]
then
  echo "Singularity is used instead of Docker; Please provide the path of the .sif file"
  exit 2
fi

if echo "$IMAGE" | grep -q "\.sif" && [[ $HPC == "false" ]]
then
  echo "Docker is used here and .sif file are only for Singulariy; Please provide the docker image name (e.g. fredmoser/accessmod:5.8.0)"
  exit 2
fi

# Get input folder path from inputs.json file (eval is required for ~)
INPUT_DIR=$(eval echo $(jq -r '.inputFolder' inputs.json))
# Check if inputs exists
if [[ ! -e "$INPUT_DIR/project.am5p" ]]
then 
  echo "Missing file: $INPUT_DIR/project.am5p"
  exit 2;
fi

if [[ ! -e "$INPUT_DIR/config.json" ]]
then 
  echo "Missing file: $INPUT_DIR/config.json"
  exit 2
fi

# Get the absolute path
INPUT_DIR=$(realpath $INPUT_DIR))

# Max travel times (can be one or multiple)
MAX_TRAVEL_TIME=$(jq -r '.maxTravelTime | join(" ")' inputs.json)
# Check if integers
# Split the string into an array
MAX_TRAVEL_TIME_ARRAY=($MAX_TRAVEL_TIME)
# Check if each element is an integer
for i in "${MAX_TRAVEL_TIME_ARRAY[@]}"
do
  if ! [[ $i =~ ^[0-9]+$ ]]
  then
    echo "Error: $i is not an integer (maxTravelTime)."
    exit 2
  fi
done

# Check if split by region region (only coverage analysis)
SPLIT=$(jq -r '.splitRegion' inputs.json)
is_boolean "$SPLIT"
# Check if zonal stat (only accessbility analysis)
ZONAL_STAT=$(jq -r '.zonalStat' inputs.json)
is_boolean "$ZONAL_STAT"

# If split by region or zonal stat we have to check the config.json file
# to see if the analysis ok
if [[ $SPLIT == "true" || $ZONAL_STAT == "true" ]]
then
  ANALYSIS=$(jq -r '.analysis' "$INPUT_DIR/config.json")
fi

# Get admin unit column anyway (will be passed anyway)
ADMIN_COL=$(jq -r '.splitRegionAdminColName' inputs.json)
if [[ $SPLIT == "true" ]]
then
  if [[ $ANALYSIS != 'amCapacityAnalysis' ]]
  then
    echo "splitRegion can be true only if AccessMod analysis is amCapacityAnalysis"
    exit 2
  fi
  if [[ -z $ADMIN_COL ]]
  then
    echo "splitRegion = true; Missing column name of administrative units in health facility shapefile in the inputs.json file"
    exit 2
  fi
else
  if [[ -n $ADMIN_COL ]]
  then
    echo "splitRegionAdminColName parameter will be ignored (splitRegion=false)"
  fi
fi

# ZonalStat
# They are passed anyway
INPUT_POP=$(jq -r '.zonalStatPop' inputs.json)
INPUT_ZONE=$(jq -r '.zonalStatZones' inputs.json)
ZONE_ID_FIELD=$(jq -r '.zonalStatIDField' inputs.json)
ZONE_LABEL_FIELD=$(jq -r '.zonalStatLabelField' inputs.json)

# Check if zonal statistics is needed
if [[ $ZONAL_STAT == "true" ]]
then
  if [[ $ANALYSIS != 'amTravelTimeAnalysis' ]]
  then
    echo "zonalStat can be true only if AccessMod analysis is amTravelTimeAnalysis"
    exit 2
  fi
  if [[ -z $INPUT_POP || -z $INPUT_ZONE || -z $ZONE_ID_FIELD || -z $ZONE_LABEL_FIELD ]]
  then
    echo "zonalStat = true; Missing parameter(s) for ZonalStat analysis in inputs.json file"
    exit 2
  fi
else
 if [[ -n $INPUT_POP ]]
 then
  echo "zonalStatPop parameter will be ignored (zonalStat=false)"
 fi
 if [[ -n $INPUT_ZONE ]]
 then
  echo "zonalStatZones parameter will be ignored (zonalStat=false)"
 fi
 if [[ -n $ZONE_ID_FIELD ]]
 then
  echo "zonalStatIDField parameter will be ignored (zonalStat=false)"
 fi
 if [[ -n $ZONE_LABEL_FIELD ]]
 then
  echo "zonalStatLabelField parameter will be ignored (zonalStat=false)"
 fi
fi

# Script location
RUN_DIR=$(realpath $(dirname $0))
# Get the current date and time in the format YYYY-MM-DD-HH-MM-SS
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
# Out directory
OUTPUT_DIR="$INPUT_DIR/out/$TIMESTAMP"
# Make out directory
mkdir -p "$OUTPUT_DIR"

# Parameters to be passed
PARAM=("$HPC" "$INPUT_DIR" "$IMAGE" "$RUN_DIR" $OUTPUT_DIR "$MAX_TRAVEL_TIME" "$SPLIT" "$ADMIN_COL" "$ZONAL_STAT" "$INPUT_POP" "$INPUT_ZONE" "$ZONE_ID_FIELD" "$ZONE_LABEL_FIELD")

# If regular server: replayDocker.sh
if [[ $HPC == "false" ]]
then
  if [[ $NOHUP == "true" ]]
  then
    nohup bash "$RUN_DIR/sh/replayDocker.sh" "${PARAM[@]}" > "$OUTPUT_DIR/nohup.out" &
    echo $! > "$OUTPUT_DIR/pid.txt"
    echo "To monitor the progress of your analysis, type: cat $OUTPUT_DIR/nohup.out"
    echo "To kill the process, type: kill \$(cat $OUTPUT_DIR/pid.txt)"
  else
    bash "$RUN_DIR/sh/replayDocker.sh" "${PARAM[@]}"
  fi
else
then
  # Make directory for slurm reports
  mkdir -p "$OUTPUT_DIR/slum_reports"
  # If split by region, run first regions.sh
  if [[ SPLIT == "true" ]]
  then
    sbatch --output "$OUTPUT_DIR/slum_reports/regions.out" "$RUN_DIR/sh/regions.sh" "${PARAM[@]}"
  else
    # To maintain same number of parameters that are passed through the different scripts
    JOB_REGIONS_ID=""
    PARAM+=("$JOB_REGIONS_ID")
    # Run array.sh to check prepare the inputs and run singularity
    sbatch --output "$OUTPUT_DIR/slum_reports/array.out" "$RUN_DIR/sh/array.sh" "${PARAM[@]}"
  fi
fi

    
