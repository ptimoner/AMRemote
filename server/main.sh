#!/bin/bash

# Get input folder path from inputs.json file (eval is required for ~)
INPUT_DIR=$(eval echo $(jq -r '.inputFolder' inputs.json))
# Check if inputs exists
if [[ ! -e $INPUT_DIR/project.amp5 ]]; then 
  echo "Missing file: $INPUT_DIR/project.amp5";
  exit 2;
fi

if [[ ! -e $INPUT_DIR/config.json ]]; then 
  echo "Missing file: $INPUT_DIR/config.json";
  exit 2;
fi

# Check if split region
# Get admin column anyway (will be passed anyway)
admin=$(jq -r '.adminColName' inputs.json)
split=$(jq -r '.splitRegion' inputs.json)
if [[ $split == "true" ]]; then
  if [[ -z $admin ]]; then
    echo "Missing column name of administrative units in health facility shapefile in the inputs.json file"
  fi
fi

# Max travel times
maxTT=$(jq -r '.maxTravelTime | length' inputs.json)
if [[ $maxT -gt 1 ]]; then
  multiTT=true
else
  multiTT=false
fi
maxVal=$(jq -r '.maxTravelTime | join(" ")' inputs.json)

# Script location
MAIN_SCRIPT_DIR=$(echo $0 | sed 's/main.sh//g')
