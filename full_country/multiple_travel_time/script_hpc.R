#!/bin/Rscript

# Load accessmod environment -----------------
source("global.R")
options(warn=-1)

# Load main parameters -----------------

# Define paths and config
pathConfig <- "/batch/config.json"
pathProject <- "/batch/project.am5p"
pathOut <- "/batch/out"
pathInputs <- "batch/inputs.json"

# Parse config.json
conf <- amAnalysisReplayParseConf(pathConfig)
inputs <- fromJSON(pathInputs)
travelTimes <- inputs$travelTimes

# Connection with GRASS database -----------------
# Import project
amAnalisisReplayImportProject(
  archive = pathProject,
  name = conf$location,
  overwrite = TRUE
)


# Number of facilities
nSel <- sum(conf$args$tableFacilities == TRUE)


for (tt in travelTimes) {
  idmsg <- sprintf("%s %s - %s min", nSel, "facilities", tt)
  
  # Print timestamp
  amTimeStamp(idmsg)
  
  # Set output dir
  pathOutTravelTime <- file.path(pathOut, tt)
  mkdirs(pathOutTravelTime)
  pathProjectOut <- file.path(pathOutTravelTime, "project_out.am5p")
  
  # Launch replay
  amAnalysisReplayExec(conf,
                       exportProjectDirectory = pathProjectOut,
                       exportDirectory = pathOutTravelTime
  )
}


# End message
amTimeStamp("Finished")

