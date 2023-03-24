#!/bin/bash



if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Illegal number of parameters" >&2
    exit 2
elif [[ $# -eq 2 ]]; then
    if [[ ! -e $1 ]]; then 
      echo "Missing dir: $1"
      exit 2;
    else
      BASH_SCRIPT_DIR=$(echo $0 | sed 's/script.sh//g')
      ${BASH_SCRIPT_DIR}init.sh $1 $2 $BASH_SCRIPT_DIR
    fi
else
  if [[ $3 == "-nb" ]]; then
    if [[ ! -e $1 ]]; then 
      echo "Missing dir: $1";
      exit 2;
    else
      BASH_SCRIPT_DIR=$(echo $0 | sed 's/script.sh//g')
      nohup ${BASH_SCRIPT_DIR}init.sh $1 $2 > $1/nohup.out &
    fi
  else
    echo "Unknown third parameter" >&2
    exit 2
  fi
fi
