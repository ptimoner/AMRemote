#!/bin/Rscript

# Load accessmod environment -----------------
source("global.R")
source("/batch/functions.R")
options(warn=-1)

# Get column name for regions
colName <- commandArgs(trailingOnly=TRUE)[1]
# In Accessmod, column names used to be in lower case
colName <- tolower(colName)

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
importProject(pathProject, conf)

# Load the health facility attribute table
amGrassNS(
  location = conf$location,
  mapset = conf$mapset,
  {
    vect <- readVECT(conf$args$inputHf)
    df <- vect@data
    hfCat <- df[, "cat"]
    hfRegion <- df[, colName]
    ## AS CHARACTER !!!! ISSUE WIHT NICOLA WHEN THEN CONCATEN
    hfIndex <- as.numeric(as.factor(hfRegion))
    hfDf <- data.frame(cat = hfCat, region = hfRegion, index = hfIndex)
    index <- unique(hfIndex)
  }
)
# For the report
toPrint <- hfDf[!duplicated(paste0(hfDf$region, "_", hfDf$index)), c(2, 3)]
toPrint <- toPrint[order(toPrint$index), ]
print(toPrint)
json <- toJSON(list(hfDf = hfDf, index = index), auto_unbox = TRUE)
write(json, file = paste0(pathOut, "/regions.json"))

