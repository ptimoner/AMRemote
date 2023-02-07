#!/bin/Rscript

# Load accessmod environment -----------------
source("global.R")
options(warn=-1)

# Get column name for regions
colName <- commandArgs(trailingOnly=TRUE)[1]

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

# Load the health facility attribute table
amGrassNS(
  location = conf$location,
  mapset = conf$mapset,
  {
    db <- execGRASS("v.db.select", parameters=list(map=conf$args$inputHf), intern=TRUE)
    con <- textConnection(db)
    # Read.table may produce issues (more columns than column names)
    df <- read.csv(con, header=TRUE, sep="|")
    close(con)
    hfCat <- df[, "cat"]
    hfRegion <- df[, colName]
    hfIndex <- as.numeric(as.factor(hfRegion))
    hfDf <- data.frame(cat = hfCat, region = hfRegion, index = hfIndex)
    index <- unique(hfIndex)
  }
)
# For the report
toPrint <- hfDf[!duplicated(paste0(hfDf$region, "_", hfDf$index)), c(2, 3)]
toPrint <- toPrint[order(toPrint$index), ]
print(toPrint)
# Save JSON for the analysis
json <- toJSON(list(hfDf = hfDf, index = index), auto_unbox = TRUE)
write(json, file = paste0(pathOut, "/inputs.json"))

