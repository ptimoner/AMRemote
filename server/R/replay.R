#!/bin/Rscript

# Load accessmod environment -----------------
source("global.R")
source("/batch/functions.R")
options(warn=-1)

# Get passed arguments
args <- commandArgs(trailingOnly = TRUE)

# Required arguments
# multiTT <- as.logical(commandArgs(trailingOnly = TRUE)[1])
maxTravelTime <- as.numeric(unlist(strsplit(commandArgs(trailingOnly = TRUE)[1], " ")))
split <- as.logical(commandArgs(trailingOnly = TRUE)[2])
zonalStat <- as.logical(commandArgs(trailingOnly = TRUE)[4])

# Load main parameters -----------------

# Define paths and config
pathConfig <- "/batch/config.json"
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

for (tt in maxTravelTime) {
  if (! split) {
    replay(conf, tt, pathOut)
  } else {
    # If split region
    amGrassNS(
      location = conf$location,
      mapset = conf$mapset,
      {
        vect <- readVECT(conf$args$inputHf)
        df <- vect@data
        hfCat <- df[, "cat"]
        hfRegion <- df[, colName]
        hfIndex <- as.numeric(as.factor(hfRegion))
        hfDf <- data.frame(cat = hfCat, region = hfRegion, index = hfIndex)
        index <- unique(hfIndex)
      }
    )
    for (ind in index) {
      selCat <- hfDf[hfDf$index == ind, "cat"]
      selRegion <- unique(hfDf[hfDf$index == ind, "region"])
      if (length(selRegion) != 1) {
        stop()
      }
      regionOut <- str_squish(selRegion)
      regionOut <- gsub("[[:space:]]", "_", regionOut)
      pathOutRegion <- file.path(pathOut, regionOut)
      # Select facilities
      # Create new data frames for the config
      facilityT <- conf$args$tableFacilities
      facilityT$amSelect <- FALSE
      facilityT[facilityT$cat %in% selCat, "amSelect"] <- TRUE
      # Update facility selection
      conf$args$tableFacilities <- facilityT
      replay(conf, tt, pathOutRegion)
    }
  }
}

if (zonalStat) {
  message("Zonal statistics...")
  inputTravelTime <- conf$args$outputTravelTime
  popLabel <- commandArgs(trailingOnly = TRUE)[5]
  zoneLabel <- commandArgs(trailingOnly = TRUE)[6]
  inputPop <- paste0("rPopulation__", popLabel)
  inputZone <- paste0("vZone__", zoneLabel)
  timeCumCosts <- maxTravelTime
  zoneIdField <- commandArgs(trailingOnly = TRUE)[7]
  zoneLabelField <- commandArgs(trailingOnly = TRUE)[8]
  amGrassNS(
    location = conf$location,
    mapset = conf$mapset,
    {
      res <- zonalAnalysis(
        inputTravelTime,
        inputPop,
        inputZone,
        timeCumCosts,
        zoneIdField,
        zoneLabelField
      )
    }
  )
  zonaStatFile <- file.path(pathOut, "zonalStat", "zonalStat.csv")
  write.csv(res, zonalStatFile, row.names = FALSE)
}

# End message
amTimeStamp("Finished")
