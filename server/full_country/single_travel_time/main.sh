#!/bin/bash
input_folder=$(jq -r '.inputFolder' inputs.json)
echo $input_folder
split=$(jq -r '.splitRegion' inputs.json)
echo $split
maxT=$(jq -r '.maxTravelTime | length' inputs.json)
echo $maxT

if [[ $maxT -gt 1 ]]; then
  multiTT=true
else
  multiTT=false
fi

echo $multiTT
maxVal=$(jq -r '.maxTravelTime | join(" ")' inputs.json)
echo $maxVal
echo $1
