#!/bin/Rscript

# Load accessmod environment -----------------
source("global.R")
options(warn=-1)

# Load main parameters -----------------

# Define paths and config
pathConfig <- "/batch/config.json"
pathProject <- "/batch/project.am5p"
pathOut <- "/batch/out"

# Parse config.json
conf <- amAnalysisReplayParseConf(pathConfig)

# Connection with GRASS database -----------------
# Import project
amAnalisisReplayImportProject(
  archive = pathProject,
  name = conf$location,
  overwrite = TRUE
)


# Number of facilities
nSel <- sum(conf$args$tableFacilities$amSelect == TRUE)
idmsg <- sprintf("%s %s", nSel, "facilities")

# Print timestamp
amTimeStamp(idmsg)

# Set output dir
pathProjectOut <- file.path(pathOut, "project_out.am5p")

# Launch replay
amAnalysisReplayExec(conf,
                     exportProjectDirectory = pathProjectOut,
                     exportDirectory = pathOut
)
# End message
amTimeStamp("Finished")

