# Dissertation
Basic R scripts used in the completion of my undergraduate dissertation for BSc Geography, University of Bristol 2020/21.

diss_functions.R contains two functions that compute the uncorrected/corrected Normalised Darkening Index (Ganey et al., 2017) for snow-algal detection in supraglacial environments.
Each requires the output of unmodified Sentinel-2A SAFE files located in the working directory downlaoded using the R package 'sen2r' (Ranghetti et al., 2020).

Selected S2A images and correction can be run in a semi-automated workflow using the script diss_loop_process.R which requires several inputs:

'dates', a vector of corrected dates in "YYYY-MM-DD" format. If > 1 year old, then they must be ordered prior to running using sen2r::s2_order()                             
'corr = TRUE', logical indicating whether corrections should be applied (TRUE; default) or not (FALSE; computes raw NDI) 
extent_sf, sf object used to crop image
dir_name,  character string for directory name used to create output files
location, character string of outmput
tile_name, character string of Sentinel-2 tilename (can be found from USGS earthexplorer, usually a 5-digit code eg "05VPG")

This takes a bunch of time as sen2cor and cloud corrections need to be run for pre-2019 data, and results in each file of > 1 GB. Server use is reccomended.

The output is a GeoTiff of the computed NDI for each date selected. Default is set to maximum 10% cloud cover of the image, but this can be adjusted within diss_loop_process.R

Louie E. Bell 2021
