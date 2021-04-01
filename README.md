# Dissertation
Basic R scripts used in the completion of my undergraduate dissertation for BSc Geography, University of Bristol 2020/21.

"Quantifying the spatio-temporal variabilty of red snow algae blooms on the south-west Greenland Ice Sheet with high-resolution satellite imaging"

'diss_functions.R' contains two functions that compute the uncorrected/corrected Normalised Darkening Index (Ganey et al., 2017) for snow-algal detection in supraglacial environments.
Each requires the output of unmodified Sentinel-2A SAFE files located in the working directory downlaoded using the R package 'sen2r' (Ranghetti et al., 2020).

'diss_loop_process.R' loops through a vector of dates and downloads them using sen2r() from the command line. I'm yet to add an ordering script, otherwise each date will need to be ordered from the Sentinel archive with sen2r::s2_order() prior to use.

This takes a bunch of time as sen2cor and cloud corrections need to be run for pre-2019 data, and results in each file of > 1 GB. Server use is reccomended.

The output is a GeoTiff of the computed NDI for each date selected.

'supraglacial_script' computes the NDWI for an image after correction with the NDSI. Threshold for NDWI (between 0 and 1) needs to be manually input. Output is a GeoTiff of the classified lake area along with the calculated lake area printed to the console.

More to come!

Louie E. Bell 2021

References:

Ganey et al.,(2017) The role of microbes in snowmelt and radiative forcing on an Alaskan icefield. Nature Geoscience. 10. 754-759.

Ranghetti et al..(2020) “sen2r: An R toolbox for automatically downloading and preprocessing Sentinel-2 satellite data”. Computers & Geosciences, 139, 104473. doi: 10.1016/j.cageo.2020.104473, URL: http://sen2r.ranghetti.info.
