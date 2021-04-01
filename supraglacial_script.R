
# requires discrete wavelength bands in format readable by rgdal
# assumes raw Sentinel-2 data (b3, b4, b5 in 10x10 res, b11 in 20x20m res)
# threshold is NDWI threshold for lake sensitivity
# set resampling method for band 11, default is nearest neighbours, can be 'bilinear'

supra_lake_area <- function(b2,b3,b4,b11,date,threshold, resample = "ngb"){
  
  require(rgdal)
  require(raster)
  require(tools)
  require(sen2r)
  
  # server preprocessing ----------------------------------------------------
  
  # error catching
    if (!file_ext(c(b2))=='jp2') {
      stop("Band 2 is not of file type .jp2")
    } else if (!file_ext(b3)=='jp2') {
      stop("Band 3 is not of file type .jp2")
    } else if (!file_ext(b4)=='jp2') {
      stop("Band 4 is not of file type .jp2")
    } else if (!file_ext(b11)=='jp2') {
      stop("Band 11 is not of file type .jp2")
    }
  
  if (is.null(threshold)){
    stop("No threshold value has been set")
  } else if (threshold >= 1){
    stop("Threshold is too large (greater than 1)")
  } else if (threshold < 0){
    stop("Threshold is too small (less than zero)")
  }
  
  if (is.null(date)){
    stop("No date has been set")
  }
  
  # read in from filepaths
  kang_b2 <- readGDAL(b2)
  kang_b3 <- readGDAL(b3)
  kang_b4 <- readGDAL(b4)
  kang_b11 <- readGDAL(b11)
  
  # produce raster
  kang_b2_rast <- raster(kang_b2)
  kang_b3_rast <- raster(kang_b3)
  kang_b4_rast <- raster(kang_b4)
  kang_b11_rast <- raster(kang_b11)
  
  if (!res(kang_b2_rast)[1]==10){
    stop("Band 2 is not 10x10m resolution")
  } else if (!res(kang_b3_rast)[1]==10){
    stop("Band 3 is not 10x10m resolution")
  } else if (!res(kang_b4_rast)[1]==10) {
    stop("Band 4 is not 10x10m resolution")
  } else if (!res(kang_b11_rast)[1]==20){
    stop("Band 11 is not 20x20m resolution")
  }
  
  paste(message(Sys.time,'\nRasters created'))
  
  rm(kang_b2)
  rm(kang_b3)
  rm(kang_b4)
  rm(kang_b11)
  
  # resample SWIR band 11 to 10m for consistency with other bands with nearest neighbours
  paste(message(Sys.time(), '\nResampling..'))
  
  if (resample == "ngb"){
  kang_b11_rast <- resample(kang_b11_rast, kang_b3_rast, method = 'ngb')
  } else if (resample == "bilinear"){
  kang_b11_rast <- resample(kang_b11_rast, kang_b3_rast, method = 'bilinear')
  }
  
  paste(message(Sys.time(), '...Done.'))
  
  # corrections -------------------------------------------------------------
  
  # create binary mask for snow NDSI
  paste(message(Sys.time(), '\nComputing snow mask index...'))
  snow_mask_index <- (kang_b3_rast - kang_b11_rast)/(kang_b3_rast + kang_b11_rast) 
  snow_mask_index[snow_mask_index<0.4] <- NA
  rm(kang_b11_rast)
  
  # mask the raw raster band data
  paste(message(Sys.time(), '\nApplying snow mask...'))
  kang_b2_mask <- mask(kang_b2_rast, snow_mask_index)
  kang_b3_mask <- mask(kang_b3_rast, snow_mask_index)
  kang_b4_mask <- mask(kang_b4_rast, snow_mask_index)
  
  rm(kang_b2_rast)
  rm(kang_b3_rast)
  rm(kang_b4_rast)
  
  # create binary mask for supraglacial lakes
  paste(message(Sys.time(), '\nComputing supraglacial lake mask...'))
  ndwi_index <- (kang_b2_mask - kang_b4_mask)/(kang_b2_mask + kang_b4_mask) 
  ndwi_index[ndwi_index<threshold] <- NA 
  
  rm(kang_b2_mask)
  rm(kang_b3_mask)
  rm(kang_b4_mask)
  
  
  # output ------------------------------------------------------------------
  
  # lake area in km squared 
  pixel_sum <- freq(ndwi_index[1,2]) + freq(ndwi_index)[2, 2]
  pixel_area_msq = pixel_sum*100
  pixel_area_km = pixel_area_msq/1e6
  
  paste(message(Sys.time(), "\nTotal lake area: ",pixel_area_km,"km^2"))
  
  # write to file
  paste(message(Sys.time(), '\nWriting to file...'))
  
  writeRaster(
    x = ndwi_index,
    filename = paste('lake_areas_',date,sep =""),
    format='GTiff',
    overwrite = T)
  
  paste(message(Sys.time(), '... Done'))
}
