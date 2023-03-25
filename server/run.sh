#!/bin/bash

# Get AccessMod image
AMVersion=$(jq -r '.AccessModVersion' inputs.json)
IMAGE="fredmoser/accessmod:$AMVersion"

# Get input folder path from inputs.json file (eval is required for ~)
INPUT_DIR=$(realpath $(eval echo $(jq -r '.inputFolder' inputs.json)))
# Check if inputs exists
if [[ ! -e $INPUT_DIR/project.amp5 ]]
then 
  echo "Missing file: $INPUT_DIR/project.amp5"
  exit 2;
fi

if [[ ! -e $INPUT_DIR/config.json ]]
then 
  echo "Missing file: $INPUT_DIR/config.json"
  exit 2
fi

# Max travel times
lengthMaxT=$(jq -r '.maxTravelTime | length' inputs.json)
if [[ $lengthMaxT -gt 1 ]]
then
  multiTT=true
else
  multiTT=false
fi
inputTravelTime=$(jq -r '.maxTravelTime | join(" ")' inputs.json)

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
then
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
PARAM=("$INPUT_DIR" "$IMAGE" "$RUN_DIR" "$multiTT" "$inputTravelTime" "$split" "$adminCol" "$zonalStat" "$inputPop" "$inputZone" "$zoneIDField" "$zoneLabelField")

bash "$RUN_DIR/sh/launchdocker.sh" "${PARAM[@]}"
