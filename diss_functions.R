
# -------------------------------------------------------------------------
# NDI uncorrected  ------------------------------------------------------------
# -------------------------------------------------------------------------

# computes uncorrected NDI using Sentinel-2 band data

# requires discrete reflectance bands in format that can be read by rgdal (.jp2 is best)

compute_NDI_uncorr <- function(band3, band4, date, location, output_filename){
  
  require(rgdal)
  require(raster)
  require(tools)
  
  # error catching
  if (!file_ext(band3)=="jp2"){
    stop("Band 3 is not of filetype '.jp2'")
  } else if (!file_ext(band4)=="jp2"){
    stop("Band 4 is not of filetype '.jp2'")
  }
  
  if (!class(location)=="character"){
    stop("Location name is not of class 'character' ")
  }
  if (!class(output_filename)=="character"){
    stop("Output filename is not of type 'character'")
  }
  
  if (!class(date)=="character"){
    stop("Date selected is not of type 'character'")
  }
  
  b3 <- readGDAL(band3)
  b4 <- readGDAL(band4)
  
  b3.r <- raster(b3)
  b4.r <- raster(b4)
  
  if (!res(b3.r)[1]==10){
    stop("Band 3 is not of resolution 10x10m")
  } else if (!res(b3.r)[2]==10){
    stop("Band 3 is not of resolution 10x10m")
  }
  
  if (!res(b4.r)[1]==10){
    stop("Band 4 is not of resolution 10x10m")
  } else if (!res(b4.r)[2]==10){
    stop("Band 4 is not of resolution 10x10m")
  }
  
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

compute_NDI_corr <- function(b2,b3,b4,b11,date, resample = "ngb"){
  
  require(rgdal)
  require(raster)
  require(tools)
  require(sen2r)
  
  # error catching 1
  if (!file_ext(b2)=="jp2"){
    stop("Band 2 is not of filetype '.jp2'")
  } else if (!file_ext(b3)=="jp2"){
    stop("Band 3 is not of filetype '.jp2'")
  } else if (!file_ext(b4)=="jp2"){
    stop("Band 4 is not of filetype '.jp2'")
  } else if (!file_ext(b11)=="jp2"){
    stop("Band 11 is not of filetype '.jp2'")
  }
  
  if (!class(date)=="character"){
    stop("Date selected is not of type 'character' ")
  }
  
  if (!resample == "ngb" || "bilinear"){
    stop("Resampling method is not of type 'ngb' (nearest neighbour) or 'bilinear' (bilinear interpolation). \n One must be selected")
  }
  
  # read in from filepaths
  
  b2_img <- readGDAL(b2)
  b3_img <- readGDAL(b3)
  b4_img <- readGDAL(b4)
  b11_img <- readGDAL(b11)
  
  # produce raster
  b2_rast <- raster(b2_img)
  b3_rast <- raster(b3_img)
  b4_rast <- raster(b4_img)
  b11_rast <- raster(b11_img)
  
  if (!res(b2_rast)[1]==10){
    stop("Band 2 is not of resolution 10x10m")
  } else if (!res(b2_rast)[2]==10){
    stop("Band 2 is not of resolution 10x10m")
  }
  
  if (!res(b3_rast)[1]==10){
    stop("Band 3 is not of resolution 10x10m")
  } else if (!res(b3_rast)[2]==10){
    stop("Band 3 is not of resolution 10x10m")
  }
  
  if (!res(b4_rast)[1]==10){
    stop("Band 4 is not of resolution 10x10m")
  } else if (!res(b4_rast)[2]==10){
    stop("Band 4 is not of resolution 10x10m")
  }
  
  if (!res(b11_r)[1]==20){
    stop("Band 11 is not of resolution 20x20m")
  } else if (!res(b11_r)[2]==20){
    stop("Band 11 is not of resolution 20x20m")
  }
  
  paste(message('Rasters created'))
  
  rm(kang_b2)
  rm(kang_b3)
  rm(kang_b4)
  rm(kang_b11)
  
  # resample SWIR band 11 to 10m for consistency with other bands with nearest neighbours
  paste(message(Sys.time(), ' Resampling..'))
  
  if (resample == 'ngb'){
    kang_b11_rast <- resample(kang_b11_rast, kang_b3_rast, method = 'ngb')
  } else if (resample == 'bilinear'){
    kang_b11_rast <- resample(kang_b11_rast, kang_b3_rast, method = 'bilinear')
  } 
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
