#!/bin/Rscript

# Load accessmod environment -----------------
source("global.R")
options(warn=-1)

# Load main parameters -----------------

# Define paths and config
pathConfig <- "/batch/config.json"
pathInputs <- "/batch/inputs.json"
pathProject <- "/batch/project.am5p"
pathOut <- "/batch/out"

# Parse config.json
conf <- amAnalysisReplayParseConf(pathConfig)

# Connection with GRASS database -----------------
# Import project
print("Importing the project...")
amAnalisisReplayImportProject(
  archive = pathProject,
  name = conf$location,
  overwrite = TRUE
)
print("Project imported...")
# Get travel time parameter
tt <- as.numeric(commandArgs(trailingOnly=TRUE)[1])

# Update facility selection
nSel <- sum(conf$args$tableFacilities$amSelect == TRUE)
idmsg <- sprintf("%s %s - %s min", nSel, "facilities", tt)
conf$args$maxTravelTime <- tt
# Print timestamp
amTimeStamp(idmsg)

# Set output dir
pathDirOut <- file.path(pathOut, tt)
mkdirs(pathDirOut)
pathProjectOut <- file.path(pathDirOut, "project_out.am5p")

# Launch replay
amAnalysisReplayExec(conf,
                     exportProjectDirectory = pathProjectOut,
                     exportDirectory = pathDirOut
)
# End message
amTimeStamp("Finished")

