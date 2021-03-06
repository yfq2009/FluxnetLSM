% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/FluxtowerSpreadsheetToNc.R
\name{CreateMetNetcdfFile}
\alias{CreateMetNetcdfFile}
\title{Creates a netcdf file for met variables}
\usage{
CreateMetNetcdfFile(metfilename, datain, latitude, longitude, site_code,
  long_sitename, datasetversion, github_rev, tier = NA, ind_start, ind_end,
  starttime, timestepsize, flux_varname, cf_name, elevation = NA,
  towerheight = NA, canopyheight = NA, short_veg_type = NA,
  long_veg_type = NA, av_precip = NA, missing, gapfill_all, gapfill_good,
  gapfill_med, gapfill_poor, min_yrs, total_missing, total_gapfilled,
  QCmeasured, QCgapfilled, ERA_gapfill = ERA_gapfill, infile, var_ind)
}
\description{
Creates a netcdf file for met variables
}

