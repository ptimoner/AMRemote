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
# Parse inputs.json
inputs <- fromJSON(pathInputs)
catRegion <- inputs$catRegion

# Connection with GRASS database -----------------
# Import project
amAnalisisReplayImportProject(
  archive = pathProject,
  name = conf$location,
  overwrite = TRUE
)

# Get service parameter
region <- commandArgs(trailingOnly=TRUE)[1]

# Main output folder
sysTime <- Sys.time()
timeFolder <- gsub("-|[[:space:]]|\\:", "", sysTime)
pathOutService <- paste0(pathOut, "/", timeFolder)
mkdirs(pathOutService)

# Select facilities
# Create new data frames for the config
facilityT <- data.frame(cat = catRegion$cat, amSelect = FALSE)
facilityT[catRegion$region == region, "amSelect"] <- TRUE

# Update facility selection
confLocal$args$tableFacilities <- facilityT
nSel <- sum(facilityT$amSelect == TRUE)
idmsg <- sprintf("%s - %s %s", region, nSel, "facilities")

# Print timestamp
amTimeStamp(idmsg)

# Set output dir
pathDirOut <- file.path(pathOutService, region)
mkdirs(pathDirOut)
pathProjectOut <- file.path(pathDirOut, "project_out.am5p")

# Launch replay
amAnalysisReplayExec(confLocal,
                     exportProjectDirectory = pathProjectOut,
                     exportDirectory = pathDirOut
)
# End message
amTimeStamp("Finished")

