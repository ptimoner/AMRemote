#!/bin/bash

# Do we use slurm management (cluster) or not ?
if which sinfo >/dev/null 2>&1; then
  echo "Slurm Workload Manager is installed"
  echo "'nohup' argument will be ignored"
  hpc=true
else
  hpc=false
fi

# Get AccessMod image
IMAGE=$(jq -r '.AccessModImage' inputs.json)
if ! echo "$IMAGE" | grep -q "\.sif" && [[ hpc == "true" ]]
then
  echo "Singularity is used instead of Docker; Please provide the path of the .sif file"
  exit 2
fi

if echo "$IMAGE" | grep -q "\.sif" && [[ hpc == "false" ]]
then
  echo "Docker is used here and .sif file are only for Singulariy; Please provide the docker image name (e.g. fredmoser/accessmod:5.8.0)"
  exit 2
fi

# Get input folder path from inputs.json file (eval is required for ~)
INPUT_DIR=$(eval echo $(jq -r '.inputFolder' inputs.json))
# Check if inputs exists
if [[ ! -e $INPUT_DIR/project.am5p ]]
then 
  echo "Missing file: $INPUT_DIR/project.am5p"
  exit 2;
fi

if [[ ! -e $INPUT_DIR/config.json ]]
then 
  echo "Missing file: $INPUT_DIR/config.json"
  exit 2
fi

INPUT_DIR=$(realpath $INPUT_DIR))

# Max travel times (can be one or multiple)
maxTravelTime=$(jq -r '.maxTravelTime | join(" ")' inputs.json)

# Check if split region
# Get admin column anyway (will be passed anyway)
adminCol=$(jq -r '.splitRegionAdminColName' inputs.json)
split=$(jq -r '.splitRegion' inputs.json)
if [[ $split == "true" ]]
then
  if [[ -z $adminCol ]]
  then
    echo "splitRegion = true; Missing column name of administrative units in health facility shapefile in the inputs.json file"
    exit 2
  fi
else
  if [[ -n $adminCol ]]
  then
    echo "splitRegionAdminColName parameter will be ignored (splitRegion=false)"
  fi
fi

# zonalStat
# There are passed anyway
inputPop=$(jq -r '.zonalStatPop' inputs.json)
inputZone=$(jq -r '.zonalStatZones' inputs.json)
zoneIDField=$(jq -r '.zonalStatIDField' inputs.json)
zoneLabelField=$(jq -r '.zonalStatLabelField' inputs.json)

# Check if zonal stat
zonalStat=$(jq -r '.zonalStat' inputs.json)

if [[ $zonalStat == "true" ]]
then
  if [[ -z $inputPop || -z $inputZone || -z $zoneIDField || -z $zoneLabelField ]]
  then
    echo "zonalStat = true; Missing parameter(s) for ZonalStat analysis in inputs.json file"
    exit 2
  fi
  analysis=$(jq -r '.analysis' "$INPUT_DIR/config.json")
  if [[ $analysis != 'amTravelTimeAnalysis' ]]
  then
    echo "zonalStat can be true only if AccessMod analysis is amTravelTimeAnalysis; check the config.json file"
    exit 2
  fi
else
 if [[ -n $inputPop ]]
 then
  echo "zonalStatPop parameter will be ignored (zonalStat=false)"
 fi
 if [[ -n $inputZone ]]
 then
  echo "zonalStatZones parameter will be ignored (zonalStat=false)"
 fi
 if [[ -n $zoneIDField ]]
 then
  echo "zonalStatIDField parameter will be ignored (zonalStat=false)"
 fi
 if [[ -n $zoneLabelField ]]
 then
  echo "zonalStatLabelField parameter will be ignored (zonalStat=false)"
 fi
fi

# Script location
RUN_DIR=$(realpath $(dirname $0))
PARAM=("$INPUT_DIR" "$IMAGE" "$RUN_DIR" "$maxTravelTime" "$split" "$adminCol" "$zonalStat" "$inputPop" "$inputZone" "$zoneIDField" "$zoneLabelField")

if [[ hpc == "false" ]]
then
  bash "$RUN_DIR/sh/launchdocker.sh" "${PARAM[@]}"
fi
