# Measuring quantities of H and DAB stained cell nuclei from tissue microarray images using FIJI

## Supplementary material

This repository includes:

* *crop_image.ijm* - The ImageJ macro for cropping a 500 by 500 pixel square out of the centres of the images
* *countNuclei2.ijm* - the ImageJ macro which automates the process of enumerating the number of cell nuclei
* *TMA_data* - A directory of the tissue microarray images to perform the algorithm upon
* *cropped* - A directory of the 500 by 500 pixel squares from the centre of each of the TMA_data images
* *TMA_data_results* - a directory containing all of the results of the analysis including the png images with the regions of interest superimposed on each image as well as a file results_table.tsv which is a tab-separated file containing the results of the counts for all of the nuclei.
