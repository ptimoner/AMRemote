#!/bin/bash

# Define the function to check if a variable is a boolean ()
# If empty set to false
function is_boolean {
  RESP=$(jq -r --arg VAR "$1" '.[$VAR]' "$RUN_DIR/inputs.json")
  if [[ -z "$RESP" ]]
  then
    RESP=false
  else
  #  Define the regular expression for matching boolean values
    BOOLEAN_REGEX="^(true|false)$"
    # Check if the input variable matches the boolean regex
    if [[ ! $RESP =~ $BOOLEAN_REGEX ]]
    then
      echo "$1 is not a boolean (true/false)."
      #exit 2
    fi
  fi
  echo $RESP
}

# Script location
RUN_DIR=$(realpath $(dirname $0))
# Check if input.json is ok (when modifying manually, errors can occur)
jq "empty" $(realpath "$RUN_DIR/inputs.json")
if [ $? -ne 0 ]; then
  echo "An error occurred. Check the inputs.json file. Exiting..."
  exit 2
fi

# Get boolean values from inputs.json file
NOHUP=$(is_boolean nohup)
SPLIT=$(is_boolean splitRegion)
ZONAL_STAT=$(is_boolean zonalStat)

# Is slurm management available (cluster)
if command -v sinfo >/dev/null 2>&1
  then
  echo "Slurm Workload Manager is installed"
  if [[ $NOHUP == "true"  ]]
  then
    echo "'nohup' argument will be ignored"
  fi
  HPC=true
  # Parameters for submitting the jobs will be retrieve; the max time will checked
  # But others not. The user is responsible to check carefully that they inputs in
  # the hpc.json file are correct.
  # Get parameters for preliminary process
  PP_NAME=$(jq -r '.Preliminary.name' "$RUN_DIR/hpc.json")
  PP_TIME=$(jq -r '.Preliminary.time' "$RUN_DIR/hpc.json")
  PP_NTASKS=$(jq -r '.Preliminary.ntasks' "$RUN_DIR/hpc.json")
  PP_CPUS_TASK=$(jq -r '.Preliminary.cpus_per_task' "$RUN_DIR/hpc.json")
  PP_MEM=$(jq -r '.Preliminary.mem' "$RUN_DIR/hpc.json")
  PP_MAIL=$(jq -r '.Preliminary.mail_type' "$RUN_DIR/hpc.json")
  # # Get the maximum time allowed for the partition from Slurm
  # ALLOWED_TIME=$(scontrol show partition "${PP_NAME}" | grep MaxTime | grep -oP 'MaxTime=\K[\d:]+')
  # # Convert the times to seconds for comparison
  # TIME_SEC=$(date -u -d "${PP_TIME}" +"%s")
  # ALLOWED_TIME_SEC=$(date -u -d "${ALLOWED_TIME}" +"%s")
  # # Check if the partition time is less than or equal to the maximum time allowed
  # if [[ "${TIME_SEC}" -le "${ALLOWED_TIME_SEC}" ]]
  # then
  #   echo "Maximum time allowed in $PREL_MAIN_NAME (preliminary process) is $ALLOWED_TIME; please check the hpc.json file"
  #   exit 2
  # fi
  # Get parameters for main analysis
  PM_NAME=$(jq -r '.Main.name' "$RUN_DIR/hpc.json")
  PM_TIME=$(jq -r '.Main.time' "$RUN_DIR/hpc.json")
  PM_NTASKS=$(jq -r '.Main.ntasks' "$RUN_DIR/hpc.json")
  PM_CPUS_TASK=$(jq -r '.Main.cpus_per_task' "$RUN_DIR/hpc.json")
  PM_MEM=$(jq -r '.Main.mem' "$RUN_DIR/hpc.json")
  PM_MAIL=$(jq -r '.Main.mail_type' "$RUN_DIR/hpc.json")
  # # Get the maximum time allowed for the partition from Slurm
  # ALLOWED_TIME=$(scontrol show partition "${PM_NAME}" | grep MaxTime | grep -oP 'MaxTime=\K[\d:]+')
  # # Convert the times to seconds for comparison
  # TIME_SEC=$(date -u -d "${PM_TIME}" +"%s")
  # ALLOWED_TIME_SEC=$(date -u -d "${ALLOWED_TIME}" +"%s")
  # # Check if the partition time is less than or equal to the maximum time allowed
  # if [[ "${TIME_SEC}" -le "${ALLOWED_TIME_SEC}" ]]
  # then
  #   echo "Maximum time allowed in $PM_NAME (main analysis) is $ALLOWED_TIME; please check the hpc.json file"
  #   exit 2
  # fi
else
  HPC=false
fi

# Get AccessMod image
IMAGE=$(eval echo $(jq -r '.AccessModImage' "$RUN_DIR/inputs.json"))
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

# Get absolute path to singularity image
if [[ $HPC == "true" ]]
then
  IMAGE=$(realpath $IMAGE)
fi

# Get input folder path from inputs.json file (eval is required for ~)
INPUT_DIR=$(eval echo $(jq -r '.inputFolder' "$RUN_DIR/inputs.json"))
# Check if inputs exists
if [[ ! -e "$INPUT_DIR/project.am5p" ]]
then 
  echo "Missing file: $INPUT_DIR/project.am5p"
  exit 2
fi

if [[ ! -e "$INPUT_DIR/config.json" ]]
then 
  echo "Missing file: $INPUT_DIR/config.json"
  exit 2
fi

# Get the absolute path
INPUT_DIR=$(realpath $INPUT_DIR)

# Max travel times (can be one or multiple)
MAX_TRAVEL_TIME=$(jq -r '.maxTravelTime | join(" ")' "$RUN_DIR/inputs.json")
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

# If split by region or zonal stat we have to check the config.json file
# to see if the analysis ok
if [[ $SPLIT == "true" || $ZONAL_STAT == "true" ]]
then
  ANALYSIS=$(jq -r '.analysis' "$INPUT_DIR/config.json")
fi

# Get admin unit column anyway (will be passed anyway)
ADMIN_COL=$(jq -r '.splitRegionAdminColName' "$RUN_DIR/inputs.json")
if [[ $SPLIT == "true" ]]
then
  if [[ $ANALYSIS != 'amCapacityAnalysis' ]]
  then
    echo "splitRegion can be true only if AccessMod analysis is amCapacityAnalysis; check your config.json file"
    exit 2
  fi
  if [[ -z $ADMIN_COL ]]
  then
    echo "splitRegion = true; Missing column name of administrative units in health facility shapefile in the "$RUN_DIR/inputs.json" file"
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
INPUT_POP=$(jq -r '.zonalStatPop' "$RUN_DIR/inputs.json")
INPUT_ZONE=$(jq -r '.zonalStatZones' "$RUN_DIR/inputs.json")
ZONE_ID_FIELD=$(jq -r '.zonalStatIDField' "$RUN_DIR/inputs.json")
ZONE_LABEL_FIELD=$(jq -r '.zonalStatLabelField' "$RUN_DIR/inputs.json")

# Check if zonal statistics is needed
if [[ $ZONAL_STAT == "true" ]]
then
  if [[ $ANALYSIS != 'amTravelTimeAnalysis' ]]
  then
    echo "zonalStat can be true only if AccessMod analysis is amTravelTimeAnalysis; check your config.json file"
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


# Get the current date and time in the format YYYY-MM-DD-HH-MM-SS
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
# Out directory
OUTPUT_DIR="$INPUT_DIR/out/$TIMESTAMP"
# Make out directory
mkdir -p "$OUTPUT_DIR"

# To save the inputs.json in the output directory (so we know what were the parameters)
cp "$RUN_DIR/inputs.json" "$OUTPUT_DIR/inputs.json"


# Create a large list of parameters with empty elements so whenever we want to add a new one, the parameters can keep their indices
# Other parameters are added in subsequent script, so adding one here forces us to modify the index of the new parameters added in
# subsequent scripts. See code_param.csv
PARAM=()
# Append empty elements to the array until it has a size of 30
while [[ ${#PARAM[@]} -lt 30 ]]
do
  PARAM+=('')
done

# Populate our list of parameters
PARAM[0]="$HPC"
PARAM[1]="$INPUT_DIR"
PARAM[2]="$IMAGE"
PARAM[3]="$RUN_DIR"
PARAM[4]="$OUTPUT_DIR"
PARAM[5]="$MAX_TRAVEL_TIME"
PARAM[6]="$SPLIT"
PARAM[7]="$ADMIN_COL"
PARAM[8]="$ZONAL_STAT"
PARAM[9]="$INPUT_POP"
PARAM[10]="$INPUT_ZONE"
PARAM[11]="$ZONE_ID_FIELD"
PARAM[12]="$ZONE_LABEL_FIELD"
PARAM[13]="$NOHUP"

# Parameters to be passed
# PARAM=("$HPC" "$INPUT_DIR" "$IMAGE" "$RUN_DIR" $OUTPUT_DIR "$MAX_TRAVEL_TIME" "$SPLIT" "$ADMIN_COL" "$ZONAL_STAT" "$INPUT_POP" "$INPUT_ZONE" "$ZONE_ID_FIELD" "$ZONE_LABEL_FIELD" "$NOHUP")

# If regular server: replayDocker.sh
if [[ "$HPC" == "false" ]]
then
  if [[ "$NOHUP" == "true" ]]
  then
    bash "$RUN_DIR/sh/replayDocker.sh" "${PARAM[@]}"

  else
    bash "$RUN_DIR/sh/replayDocker.sh" "${PARAM[@]}"
  fi
else
  # Preliminaray jobs
  PARAM[14]="$PP_NAME"
  PARAM[15]="$PP_TIME"
  PARAM[16]="$PP_NTASKS"
  PARAM[17]="$PP_CPUS_TASK"
  PARAM[18]="$PP_MEM"
  PARAM[19]="$PP_MAIL"
  # Main jobs
  PARAM[20]="$PM_NAME"
  PARAM[21]="$PM_TIME"
  PARAM[22]="$PM_NTASKS"
  PARAM[23]="$PM_CPUS_TASK"
  PARAM[24]="$PM_MEM"
  PARAM[25]="$PM_MAIL"
  
  # Make directory for slurm reports
  mkdir -p "$OUTPUT_DIR/slum_reports"
  # Make random jobname (so we avoid conflict when accessing job id using the name, when we run multiple analysis at the same time)
  JOB_NAME="1_$(tr -dc 'a-zA-Z' < /dev/urandom | head -c 5)"
  PARAM[26]="$JOB_NAME"
  # If split by region, run first regions.sh
  if [[ $SPLIT == "true" ]]
  then
    sbatch \
    --output="$OUTPUT_DIR/slum_reports/regions.out" \
    --job-name="$JOB_NAME" \
    --partition="$PP_NAME" \
    --time="$PP_TIME" \
    --ntasks="$PP_NTASKS" \
    --cpus-per-task="$PP_CPUS_TASK" \
    --mem="$PP_MEM" \
    --mail-type="$PP_MAIL" \
    "$RUN_DIR/sh/regions.sh" "${PARAM[@]}"
    # sbatch --output "$OUTPUT_DIR/slum_reports/regions.out" --job-name="$JOB_NAME" --partition="$PP_NAME" --time="$PP_TIME" "$RUN_DIR/sh/regions.sh" "${PARAM[@]}"
  else
    # # To maintain same number of parameters that are passed through the different scripts
    # # JOB_ID 
    # JOB_REGIONS_ID=""
    # PARAM+=("$JOB_REGIONS_ID")
    # Run array.sh to check prepare the inputs and run singularity
    # sbatch --output "$OUTPUT_DIR/slum_reports/array.out" --job-name="$JOB_NAME" --partition="$PP_NAME" --time="$PP_TIME" "$RUN_DIR/sh/array.sh" "${PARAM[@]}"
    sbatch \
    --output="$OUTPUT_DIR/slum_reports/array.out" \
    --job-name="$JOB_NAME" \
    --partition="$PP_NAME" \
    --time="$PP_TIME" \
    --ntasks="$PP_NTASKS" \
    --cpus-per-task="$PP_CPUS_TASK" \
    --mem="$PP_MEM" \
    --mail-type="$PP_MAIL" \
    "$RUN_DIR/sh/array.sh" "${PARAM[@]}"
  fi
fi