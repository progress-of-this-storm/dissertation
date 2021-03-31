
# -------------------------------------------------------------------------
# NDI uncorrected  ------------------------------------------------------------
# -------------------------------------------------------------------------

# computes uncorrected NDI using Sentinel-2 band data

# requires discrete reflectance bands in format that can be read by rgdal (.jp2 is best)

compute_NDI_uncorr <- function(band3, band4, date, location, output_filename){
  
  require(rgdal)
  require(raster)
  require(tools)
  
  b3 <- readGDAL(band3)
  b4 <- readGDAL(band4)
  
  b3.r <- raster(b3)
  b4.r <- raster(b4)
  
  paste(message(Sys.time(), '   Rasters created'))
  
  rm(b3)
  rm(b4)
  
  paste(message(Sys.time(), '   Computing snow algal band ratio'))
  
  NDI <- (b4.r-b3.r)/(b4.r+b3.r)
  NDI[NDI<= 0] <- NA
  
  paste(message(Sys.time(), '   Writing to file'))
  
  writeRaster(
    x =NDI,
    filename = paste(output_filename,'/',location,'_',date,'_NDI', sep =""),
    format='GTiff',
    overwrite = T)
  
  paste(message(Sys.time(), '   ...Done'))
  
}


# -------------------------------------------------------------------------
# corrected NDI processing ------------------------------------------------
# -------------------------------------------------------------------------

compute_NDI_corr <- function(b2,b3,b4,b11,date){
  
  require(rgdal)
  require(raster)
  require(tools)
  require(sen2r)
  
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
  
  paste(message('Rasters created'))
  
  rm(kang_b2)
  rm(kang_b3)
  rm(kang_b4)
  rm(kang_b11)
  
  # resample SWIR band 11 to 10m for consistency with other bands with nearest neighbours
  paste(message(Sys.time(), ' Resampling..'))
  kang_b11_rast <- resample(kang_b11_rast, kang_b3_rast, method = 'ngb')
  paste(message(Sys.time(), '...Done.'))
  
  # corrections -------------------------------------------------------------
  
  # create binary mask for snow NDSI
  paste(message(Sys.time(), ' Computing snow mask index...'))
  snow_mask_index <- (kang_b3_rast - kang_b11_rast)/(kang_b3_rast + kang_b11_rast) 
  snow_mask_index[snow_mask_index<0.4] <- NA
  rm(kang_b11_rast)
  
  # mask the raw raster band data
  paste(message(Sys.time(), ' Applying snow mask...'))
  kang_b2_mask <- mask(kang_b2_rast, snow_mask_index)
  kang_b3_mask <- mask(kang_b3_rast, snow_mask_index)
  kang_b4_mask <- mask(kang_b4_rast, snow_mask_index)
  
  rm(kang_b2_rast)
  rm(kang_b3_rast)
  rm(kang_b4_rast)
  
  # create binary mask for supraglacial lakes
  paste(message(Sys.time(), ' Computing supraglacial lake mask...'))
  ndwi_index <- (kang_b2_mask - kang_b4_mask)/(kang_b2_mask + kang_b4_mask) 
  ndwi_index[ndwi_index>0.18] <- NA #other papers suggest a mask of 0.12?
  
  rm(kang_b2_mask)
  
  # mask the snow-corrected data
  paste(message(Sys.time(), ' Applying lake mask...'))
  kang_b3_mask <- mask(kang_b3_mask, ndwi_index)
  kang_b4_mask <- mask(kang_b4_mask, ndwi_index)
  
  # compute the algal band ratio
  paste(message(Sys.time(), ' Computing NDI band ratio...'))
  kang_NDSI <- (kang_b4_mask-kang_b3_mask)/(kang_b3_mask+kang_b4_mask)
  kang_NDSI[kang_NDSI<0] <- NA
  
  rm(kang_b3_mask)
  rm(kang_b4_mask)
  
  # output ------------------------------------------------------------------
  
  # write to file
  paste(message(Sys.time(), ' Writing to file...'))
  
  writeRaster(
    x = kang_NDSI,
    filename = paste('kang_',date,'_algae_early', sep =""),
    format='GTiff',
    overwrite = T)
  
  paste(message(Sys.time(), '... Done'))
}
