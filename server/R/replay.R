#!/bin/Rscript

# Load accessmod environment -----------------
source("global.R")
options(warn=-1)

args <- commandArgs(trailingOnly = TRUE)
print(args)
stop("Bye")
# Load main parameters -----------------

# Define paths and config
pathConfig <- "/batch/config.json"
pathProject <- "/batch/project.am5p"
pathOut <- "/batch/out"
# Output folder
sysTime <- Sys.time()
timeFolder <- gsub("-|[[:space:]]|\\:", "", sysTime)
pathDirOut <- file.path(pathOut, timeFolder)
mkdirs(pathDirOut)

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

# Number of facilities
nSel <- sum(conf$args$tableFacilities$amSelect == TRUE)
idmsg <- sprintf("%s %s", nSel, "facilities")

# Print timestamp
amTimeStamp(idmsg)

# Set output dir
pathProjectOut <- file.path(pathDirOut, "project_out.am5p")

# Launch replay
amAnalysisReplayExec(conf,
                     exportProjectDirectory = pathProjectOut,
                     exportDirectory = pathDirOut
)
# End message
amTimeStamp("Finished")

# if (zonal)

inputTravelTime <- conf$args$outputTravelTime
inputPop <- "rPopulation__rPopulation_Corrected"
inputZone <- "vZone__vAdmin1"
timeCumCosts <- c(100, 120)
zoneIdField <- "cat"
zoneLabelField <- "adm1_pt"


amGrassNS(
  location = conf$location,
  mapset = conf$mapset,
  {
    res <- amZonalAnalysis(
    inputTravelTime,
    inputPop,
    inputZone,
    timeCumCosts,
    zoneIdField,
    zoneLabelField
    )
  }
)

print(res)