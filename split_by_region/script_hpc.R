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
hfDf <- inputs$hfDf

# Connection with GRASS database -----------------
# Import project
print("Importing the project...")
amAnalisisReplayImportProject(
  archive = pathProject,
  name = conf$location,
  overwrite = TRUE
)
print("Project imported...")

# Get region parameter
ind <- commandArgs(trailingOnly=TRUE)[1]
selCat <- hfDf[hfDf$index == ind, "cat"]
selRegion <- unique(hfDf[hfDf$index == ind, "region"])
if (length(selRegion) != 1) {
  stop()
}

regionOut <- str_squish(selRegion)
regionOut <- gsub("[[:space:]]", "_", regionOut)

# # Main output folder
# mkdirs(pathOut)

# Select facilities
# Create new data frames for the config
facilityT <- conf$args$tableFacilities
facilityT$amSelect <- FALSE
# print(selCat)
# print(class(selCat))
# print(class(facilityT$cat))
# print(facilityT$cat)
facilityT[facilityT$cat %in% selCat, "amSelect"] <- TRUE

# Update facility selection
conf$args$tableFacilities <- facilityT
nSel <- sum(facilityT$amSelect == TRUE)
idmsg <- sprintf("%s - %s %s", selRegion, nSel, "facilities")

# Print timestamp
amTimeStamp(idmsg)

# Set output dir
pathDirOut <- file.path(pathOut, regionOut)
mkdirs(pathDirOut)
pathProjectOut <- file.path(pathDirOut, "project_out.am5p")

# Launch replay
amAnalysisReplayExec(conf,
                     exportProjectDirectory = pathProjectOut,
                     exportDirectory = pathDirOut
)
# End message
amTimeStamp("Finished")

