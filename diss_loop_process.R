
# requires vector of selected dates in "YYYY-MM-DD" format
             # loop will return error if chosen dates are offline (in the Sen2 archive if > 1 year old)
             # therefore they must be ordered prior to running using sen2r::s2_order()

process_dates_NDI <- function(dates, # vector of dates as above
                              corr = T, # correction if TRUE, raw NDI if FALSE
                              extent_sf, # sf object used to find image
                              dir_name, # directory name used for output files
                              location, # location of area used
                              tile_name, # Sentinel-2 tilename (can be found from USGS earth explorer)
                              max_cloud){ # max % for cloud cover
    
  source('diss_functions.R') # assumes diss_functions.R is in the working directory
  
  require(sen2r)
  require(rgdal)
  require(tools)
  require(raster)
  require(geojsonsf)
  

# error catching ----------------------------------------------------------

  if (!file_ext(extent_sf)=='sf'){
    stop("Spatial extent is not of type .sf")
  }
  
  if (!class(dir_name) == "character"){
    stop("Location is not of type 'character'")
  }
  
  if (!class(tile_name)=="character"){
    stop("Tile name is not of type 'character' ")
  }


  for(i in 1:length(dates)){
  
  date <- dates[i]
  
  # create output directories
  dir.create(paste(date,'-l2a_out', sep = ""))
  dir.create(paste(date,"-l1c_out", sep =""))
  dir.create(paste(date,"_output", sep =""))
  
  sen2r(
    write_scihub_login(username = '######', password = '#######'), # insert here 
    
    gui = FALSE, # set shiny app GUI to pop us as FALSE
    
    #step_atmcorr = "l2a", # for l2a or l1c data
    
    extent = extent_sf, # 
    
    extent_name = dir_name, # this is what the output file will be called
    
    timewindow = c(as.Date(date)),
    
    #timeperiod = 'seasonal',
    
    list_prods = c("BOA"), # we only want Bottom Of Atmosphere data
    
    #list_indices = c("NDSI"), # here I say I want an index that classifies snow, (NA if unnecesary)
    
    #list_rgb = c("RGB432B"), # here I say I want a normal redgreenblue image (bands 4, 3 and 2)
    
    mask_type = "cloud_and_shadow", # I want to hide (mask) the clouds and shadows
    
    max_mask = max, # only 10% of the image can be masked, else it gets rid of it
    
    max_cloud_safe = max_cloud,
    
    path_l1c = paste(date,'-l1c_out', sep = ""), # save to the directories
    
    path_l2a = paste(date,'-l2a_out', sep = ""), # save to the directories
    
    path_out = paste(date,'_output', sep = ""),
    
    clip_on_extent = TRUE, # this says that I want to clip the image to the extent I selected earlier, if not, the whole tile is used
    
    extent_as_mask= TRUE, 
    
    s2tiles_selected = tile_name,
    
    rm_safe = 'l1c', # remove the l1c data from directory
    
    sen2cor_use_dem = TRUE
  )
  
  
  # grab the image files from folder ----------------------------------------
  main.dir <- paste(getwd(),date,"-l2a_out", sep = "")
  SAFE.dir <- list.files(paste(main.dir))
  L2A_prod <- list.files(paste(main.dir,SAFE.dir,'GRANULE', sep = "/"))
  files_10m <- list.files(paste(main.dir,SAFE.dir,'GRANULE',L2A_prod,'IMG_DATA','R10m', sep = "/"))
  files_20m <- list.files(paste(main.dir,SAFE.dir,'GRANULE',L2A_prod,'IMG_DATA','R20m', sep = "/"))
  
  if (corr == T){

  # perform processing operation --------------------------------------------
  compute_NDI_corr(
    b2 = paste(main.dir,SAFE.dir,'GRANULE',L2A_prod,'IMG_DATA','R10m',files_10m[2], sep = "/"),
    b3 = paste(main.dir,SAFE.dir,'GRANULE',L2A_prod,'IMG_DATA','R10m',files_10m[3], sep = "/"),
    b4 = paste(main.dir,SAFE.dir,'GRANULE',L2A_prod,'IMG_DATA','R10m',files_10m[4], sep = "/"),
    b11 = paste(main.dir,SAFE.dir,'GRANULE',L2A_prod,'IMG_DATA','R20m',files_20m[8], sep = "/"),
    date=as.Date(date))
    paste(message("Finished date: ",date, sep=""))
  } 
  
  else
    compute_NDI_uncorr(
      b3 = paste(main.dir,SAFE.dir,'GRANULE',L2A_prod,'IMG_DATA','R10m',files_10m[3], sep = "/"),
      b4 = paste(main.dir,SAFE.dir,'GRANULE',L2A_prod,'IMG_DATA','R10m',files_10m[4], sep = "/"),
      date=as.Date(date),
      location = location,
      output_filename = "location")
  
  paste(message("Finished date: ",date, sep=""))
}
  
} 
