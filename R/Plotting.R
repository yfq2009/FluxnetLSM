# Plotting.R
#
# author: Anna Ukkola UNSW 2017
#

#' Plots standard analysis plots from netcdf data
#'
#' @param ncfile an open netcdf file
#' @param analysis_type vector of plot names: c("annual", "diurnal", "timeseries")
#' @param vars vector of variable names to plot
#' @param outfile output path prefix, including directory
#'
#' @export
#' 
plot_nc <- function(ncfile, analysis_type, vars, outfile){
  
  #Initialise warnings
  warnings <- ""
  
  #Separate data and QC variables
  data_vars <- vars[!grepl("_qc", vars)]
  qc_vars   <- vars[grepl("_qc", vars)]
  
    
  #Load data variables and units from NetCDF file
  data        <- lapply(data_vars, ncvar_get, nc=ncfile)
  data_units  <- lapply(data_vars, function(x) ncatt_get(nc=ncfile, varid=x, 
                                                        attname="units")$value)
  #fluxnet_names
  fluxnet_names  <- lapply(data_vars, function(x) ncatt_get(nc=ncfile, varid=x, 
                                                         attname="Fluxnet_name")$value)
  names(data)       <- data_vars
  names(data_units) <- data_vars
  
  
  #Retrieve time variable and units
  time       <- ncvar_get(ncfile, "time")
  time_units <- ncatt_get(ncfile, "time", "units")$value
  
  #Find time attributes
  timing <- GetTimingNcfile(ncfile)  
  
  #Abort if time unit not in seconds
  if(!grepl("seconds since", time_units)){
    warn <- paste("Unknown time units, unable to produce",
                     "output plots. Expects time in seconds,",
                     "currently in units of", time_units)
    warnings <- append_and_warn(warn=warn, warnings)
    return(warnings)
  }
  
  
  #Time step size  
  timestepsize <- time[2] - time[1]
  
  #Find start year
  startdate <- as.Date(strsplit(time_units, "seconds since ")[[1]][2])
  syear     <- as.numeric(format(startdate, "%Y"))
  
  
  ## If rainfall (P) and air temp (TA_F_MDS) being plotted, ##
  ## convert to units mm/timestepsize and deg C             ##
  if(any(fluxnet_names=="P")){
    ind <- which(fluxnet_names=="P")
    
    #If recognised units, convert to mm/timestep
    if(data_units[[ind]]=="mm/s" | data_units[[ind]]=="mm s-1" | 
       data_units[[ind]]=="kg/m2/s" | data_units[[ind]]=="kg m-2 s-1"){
      
      data[[ind]] <- data[[ind]] * timestepsize
      data_units[[ind]] <- paste("mm/", timestepsize/60, "min", sep="")
    }
  }
  if(any(fluxnet_names=="TA_F_MDS")){
    ind <- which(fluxnet_names=="TA_F_MDS")
    
    #If recognised units, convert to mm/timestep
    if(data_units[[ind]]=="K"){
      data[[ind]] <- data[[ind]] - 273.15
      data_units[[ind]] <- paste("C")
    }
  }
  
  
  ## Load qc variables if available ##
  if(length(qc_vars) > 0) {
    qc_data <- lapply(qc_vars, ncvar_get, nc=ncfile)
    names(qc_data) <- qc_vars  
  }

  
  ## Number of variables to plot ##
  no_vars <- length(data_vars)
 
  ### Loop through analysis types ###
  for(k in 1:length(analysis_type)){
    

    ##################
    ## Annual cycle ##
    ##################
    if(analysis_type[k]=="annual"){
      
      #Initialise file
      pdf(paste(outfile, "AnnualCycle.pdf", sep=""), height=no_vars*5,
          width=no_vars*5)
      
      par(mai=c(0.6,0.7,0.7,0.2))
      par(omi=c(0.4,0.2,0.2,0.1))
      par(mfrow=c(ceiling(sqrt(no_vars)), ceiling(sqrt(no_vars))))
      
      #Plot
      for(n in 1:length(data)){
        
        AnnualCycle(obslabel="", acdata=as.matrix(data[[n]]),
                    varname=data_vars[n], 
                    ytext=paste(data_vars[n], " (", data_units[n], ")", sep=""), 
                    legendtext=data_vars[n], 
                    timestepsize=timestepsize,
                    whole=timing$whole, plotcolours="blue",
                    na.rm=TRUE)  
      }
  
      #Close file
      dev.off()
      
      
      
    ###################
    ## Diurnal cycle ## 
    ###################
    } else if(analysis_type[k]=="diurnal"){
      
      
      #Initialise file
      pdf(paste(outfile, "DiurnalCycle.pdf", sep=""), height=no_vars*10,
          width=no_vars*10)
      
      par(mai=c(0.6,0.7,0.7,0.2))
      par(omi=c(0.2,0.2,0.2,0.1))
      par(mfrow=c(ceiling(sqrt(no_vars)), ceiling(sqrt(no_vars))))
      
      #Plot
      for(n in 1:length(data)){  
        
        #Find corresponding QC variable (if available)
        qc_ind <- which(qc_vars==paste(data_vars[n], "_qc", sep=""))
        
        #Extract QC data and replace all gap-filled values with 0
        # and measured with 1 (opposite to Fluxnet but what PALS expects)
        if(length(qc_ind) >0){
          
          var_qc <- qc_data[[qc_ind]]
          
          var_qc[var_qc > 0]  <- 2 #replace gap-filled values with a temporary value
          var_qc[var_qc == 0] <- 1 #set measured to 1
          var_qc[var_qc == 2] <- 0 #set gap-filled to 0
          
          #Else set to PALS option corresponding to no QC data
        } else {
          var_qc <- matrix(-1, nrow = 1, ncol = 1)
        }
        
        
        DiurnalCycle(obslabel=data_vars[n],dcdata=as.matrix(data[[n]]),
                     varname=data_vars[n], 
                     ytext=paste(data_vars[n], " (", data_units[n], ")", sep=""), 
                     legendtext=data_vars[n], timestepsize=timestepsize,
                     whole=timing$whole, plotcolours="blue",
                     #vqcdata=as.matrix(var_qc),
                     na.rm=TRUE)  
      }
      
      #Close file
      dev.off()
      
      
      
    ################################
    ## 14-day running time series ##
    ################################
    } else if(analysis_type[k]=="timeseries"){

      #Initialise file
      pdf(paste(outfile, "Timeseries.pdf", sep=""), height=no_vars*2.2*5, width=no_vars*1.4*5)
      
      par(mai=c(0.6,0.6,0.4,0.2))
      par(omi=c(0.2,0.2,0.2,0.1))
      par(mfrow=c(ceiling(no_vars/2), 2))
      

      #Plot
      for(n in 1:length(data)){
  
        
        #Find corresponding QC variable (if available)
        qc_ind <- which(qc_vars==paste(data_vars[n], "_qc", sep=""))
        
        #Extract QC data and replace all gap-filled values with 0
        # and measured with 1 (opposite to Fluxnet but what PALS expects)
        if(length(qc_ind) >0){
          
          var_qc <- qc_data[[qc_ind]]
          
          var_qc[var_qc > 0]  <- 2 #replace gap-filled values with a temporary value
          var_qc[var_qc == 0] <- 1 #set measured to 1
          var_qc[var_qc == 2] <- 0 #set gap-filled to 0
          
          #If first value missing, set to measured (to avoid an error when PALS
          #checks if first value -1)
          if(is.na(var_qc[1])){ var_qc[1] <- 0}
          
          
          #Else set to PALS option corresponding to no QC data
        } else {
          var_qc <- matrix(-1, nrow = 1, ncol = 1)
        }
        
        
        Timeseries(obslabel="", tsdata=as.matrix(data[[n]]), 
                   varname=data_vars[n],
                   ytext=paste(data_vars[n], " (", data_units[n], ")", sep=""), 
                   legendtext=data_vars[n],
                   plotcex=1.5, timing=timing, 
                   smoothed = FALSE, winsize = 1, 
                   plotcolours="blue", 
                   vqcdata = as.matrix(var_qc),
                   na.rm=TRUE)
      
      }

    dev.off()  
      
      
    
    ###################################################
    ## Else: Analysis type not known, return warning ##
    ###################################################
    } else {
      
      warn <- paste("Attempted to produce output plot but analysis
                    type not known. Accepted types are 'annual', 'diurnal'
                    and 'timeseries' but ", "'", analysis_type[k], "' was 
                    passed to function.", sep="")
      
      warnings <- append_and_warn(warn=warn, warnings)
    }
    
    
    
  } #analyses
  
  return(warnings)
  
} #function
