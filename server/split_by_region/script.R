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
print("Importing the project...")
amAnalisisReplayImportProject(
  archive = pathProject,
  name = conf$location,
  overwrite = TRUE
)

# Get regions
# Load the health facility attribute table
amGrassNS(
  location = conf$location,
  mapset = conf$mapset,
  {
    # db <- execGRASS("v.db.select", parameters=list(map=conf$args$inputHf), intern=TRUE)
    # con <- textConnection(db)
    # # Read.table may produce issues (more columns than column names)
    # df <- read.csv(con, header=TRUE, sep="|")
    # close(con)
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
}

# End message
amTimeStamp("Finished")

