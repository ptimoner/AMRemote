# Import project
importProject <- function (pathProject, conf) {
  amAnalisisReplayImportProject(
  archive = pathProject,
  name = conf$location,
  overwrite = TRUE
)}

# Replay function
replay <- function (conf, tt, pathOut) {
  nSel <- sum(conf$args$tableFacilities$amSelect == TRUE)
  idmsg <- sprintf("%s %s - %s min", nSel, "facilities", tt)
  
  # Print timestamp
  amTimeStamp(idmsg)
  
  # Set output dir
  pathDirOut <- file.path(pathOut, paste0(tt, "-min"))
  mkdirs(pathDirOut)
  pathProjectOut <- file.path(pathDirOut, "project_out.am5p")
  
  # Launch replay
  amAnalysisReplayExec(conf,
                       exportProjectDirectory = pathProjectOut,
                       exportDirectory = pathDirOut
  )
}

# Replay splitting by region
byRegion <- function (hfDf, ind, conf, pathOut, tt) {
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

# From amZonalAnalysis
zonalAnalysis <- function(
    inputTravelTime,
    inputPop,
    inputZone,
    timeCumCosts,
    zoneIdField,
    zoneLabelField
) {
  
  res <- list(
    table = data.frame(
      id                = "-",
      label             = "-",
      time_m            = "-",
      popTotal          = "-",
      popTravelTime     = "-",
      popCoveredPercent = "-"
    ),
    empty = TRUE
  )
  
  inputZoneTemp <- sprintf(
    "tmp_zones_%s",
    digest::digest(c(
      inputZone,
      zoneLabelField,
      zoneIdField
    ))
  )
  
  if (!amRastExists(inputZoneTemp)) {
    #
    # Create raster version of admin zone.
    #
    execGRASS("v.to.rast",
              input = inputZone,
              output = inputZoneTemp,
              type = "area",
              use = "attr",
              label_column = zoneLabelField,
              attribute_column = zoneIdField,
              flags = "overwrite"
    )
  }
  
  
  validCost <- all(timeCumCosts > 0)
  hasZone <- !is.null(inputZone)
  hasPop <- !is.null(inputPop)
  checkTempZone <- execGRASS("g.list",
                             type = "raster",
                             pattern = inputZoneTemp,
                             intern = T
  )
  hasTempZone <- isTRUE(inputZoneTemp == checkTempZone)
  
  if (validCost && hasZone && hasPop && hasTempZone) {
    res$empty <- FALSE
    timeCumCosts <- unique(timeCumCosts)
    timeCumCosts <- sort(timeCumCosts)
    lTimeCumCosts <- length(timeCumCosts)
    for (i in 1:lTimeCumCosts) {
      cost <- timeCumCosts[i]
      #
      # extract population under coverage area ignore negative.
      #
      popUnderTravelTime <- sprintf(
        "tmp__pop_under_travel_time = ( %1$s >= 0 && %1$s < %2$s ) ? %3$s : null()",
        inputTravelTime,
        cost,
        inputPop
      )
      
      execGRASS("r.mapcalc",
                expression = popUnderTravelTime,
                flags = "overwrite"
      )
      
      statZonePopTravelTime <- execGRASS("r.univar",
                                         map    = "tmp__pop_under_travel_time",
                                         zones  = inputZoneTemp,
                                         flags  = c("g", "t"),
                                         intern = T
      ) %>%
        amCleanTableFromGrass(cols = c("zone", "label", "sum"))
      
      statZonePopTotal <- execGRASS("r.univar",
                                    map    = inputPop,
                                    zones  = inputZoneTemp,
                                    flags  = c("g", "t"),
                                    intern = T
      ) %>%
        amCleanTableFromGrass(cols = c("zone", "label", "sum"))
      
      statZoneMerge <- merge(
        statZonePopTotal,
        statZonePopTravelTime,
        by = c("zone", "label"),
        all.x = TRUE
      )
      
      names(statZoneMerge) <- c(
        zoneIdField,
        zoneLabelField,
        "popTotal",
        "popTravelTime"
      )
      
      #
      # Compute percentage
      #
      statZoneMerge$popCoveredPercent <- (
        statZoneMerge$popTravelTime / statZoneMerge$popTotal
      ) * 100
      
      #
      # Replace na by zero
      #
      statZoneMerge[is.na(statZoneMerge)] <- 0
      
      #
      # Add costs (if multiple costs)
      #
      statZoneMerge$time_m <- cost
      
      #
      # Re-order
      #
      statZoneMerge <- statZoneMerge[, c(
        zoneIdField,
        zoneLabelField,
        "time_m",
        "popTotal",
        "popTravelTime",
        "popCoveredPercent"
      )]
      if (i == 1) {
        res$table <- statZoneMerge[order(statZoneMerge$popCoveredPercent), ]
      } else {
        res$table <- rbind(
          res$table,
          statZoneMerge[order(statZoneMerge$popCoveredPercent), ]
        )
      }
    }
  }
  return(res)
}