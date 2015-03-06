if (!getBoolean("This script will remove all images from your session. Do you wish to continue?")) {
	exit;
}

resetEnvironment();
open(File.openDialog("Choose a picture to open"));

Dialog.create("Nucleus Count Options");

Dialog.addChoice("Nucleus stain colour:", newArray("DAB", "H"));
Dialog.addNumber("Lower gaussian blur sigma:", 2);
Dialog.addNumber("Upper gaussian blur sigma:", 6);
Dialog.addCheckbox("Remove outliers:", true);
Dialog.addChoice("Threshold type:", newArray("yen", "triangle"));

Dialog.addNumber("Maximum filter radius:", 4);
Dialog.addNumber("Minimum filter radius:", 4);

Dialog.addCheckbox("Use Watershed", true);
Dialog.show();

nucleusColour = Dialog.getChoice();
otherColour = "";
if (nucleusColour == "DAB") {
	otherColour = "H";
} else {
	otherColour = "DAB";
}
lowerGaussianSigma = Dialog.getNumber();
upperGaussianSigma = Dialog.getNumber();
willRemoveOutliers = Dialog.getCheckbox();
thresholdType = Dialog.getChoice();
maximumFilterRadius = Dialog.getNumber();
minimumFilterRadius = Dialog.getNumber();
isUsingWatershed = Dialog.getCheckbox();

nucleusCount = CountNuclei(nucleusColour, otherColour, lowerGaussianSigma,
	upperGaussianSigma, willRemoveOutliers, thresholdType, maximumFilterRadius,
	minimumFilterRadius, isUsingWatershed);

run("Clear Results");

writeResults(nucleusColour, otherColour,
lowerGaussianSigma, upperGaussianSigma, willRemoveOutliers, thresholdType,
maximumFilterRadius, minimumFilterRadius, isUsingWatershed, nucleusCount);


/**
 * @param thresholdType can be value ["yen", "triangle"] 
 */
function CountNuclei (nucleusColour, otherColour,
	lowerGaussianSigma, upperGaussianSigma, willRemoveOutliers, thresholdType,
	maximumFilterRadius, minimumFilterRadius, isUsingWatershed) {
	run("Duplicate...", "title=copy_of_original");
	
	selectWindow ("copy_of_original");
	colourDeconvolution ("copy_of_original");
	
	selectWindow (nucleusColour);
	run("Duplicate...", "title="+nucleusColour+"_Duplicate");
	
	selectWindow (nucleusColour);
	run("Gaussian Blur...", "sigma="+lowerGaussianSigma);
	rename(nucleusColour + "_Gaussian_lower");
	
	selectWindow (nucleusColour+"_Duplicate");
	run("Gaussian Blur...", "sigma="+upperGaussianSigma);
	rename(nucleusColour+"_Gaussian_upper");
	
	imageCalculator("Add create 32-bit", nucleusColour+"_Gaussian_lower", nucleusColour+"_Gaussian_upper");
	
	selectWindow ("Result of "+nucleusColour+"_Gaussian_lower");
	rename(nucleusColour+"_sum_of_Gaussian");
	
	selectWindow (nucleusColour+"_sum_of_Gaussian");
	
	// maybe need to change this bit 
	if (willRemoveOutliers) {
		run("Remove Outliers...", "radius=4 threshold=10 which=Bright");
	}
	
	selectWindow ("Other");
	
	imageCalculator("Add create 32-bit", nucleusColour+"_sum_of_Gaussian", "Other"); 
	selectWindow ("Result of "+nucleusColour+"_sum_of_Gaussian");
	rename(nucleusColour+"_sum_of_Gaussian_AND_other");
	
	imageCalculator("Subtract create 32-bit", nucleusColour+"_sum_of_Gaussian_AND_other", otherColour); 
	selectWindow ("Result of "+nucleusColour+"_sum_of_Gaussian_AND_other");
	rename (nucleusColour+"_sum_of_Gaussian_AND_other_Minus_"+otherColour);
	
	selectWindow (nucleusColour+"_sum_of_Gaussian_AND_other_Minus_"+otherColour);
	// look at this bit - might need changed 
	run("Maximum...", "radius="+maximumFilterRadius);
	run("Minimum...", "radius="+minimumFilterRadius);

	if (thresholdType == "yen") {
		setAutoThreshold("Yen dark");
	} else if (thresholdType == "triangle") {
		run("8-bit");
		run("Triangle Algorithm");
	}
	//run("Threshold...");
	
	run("Make Binary", "thresholded remaining black");
	run("Invert");
	if (isUsingWatershed) {
		run("Watershed");
	}
	
	run("Analyze Particles...", " ");

	nucleusCount = nResults;

	return nucleusCount;
}

function writeResults(nucleusColour, otherColour, lowerGaussianSigma, upperGaussianSigma, willRemoveOutliers, thresholdType, maximumFilterRadius, minimumFilterRadius, isUsingWatershed, nucleusCount) {
	numResults = nResults;
	setResult("Nucleus Colour", numResults, nucleusColour);
	setResult("Lower Gaussian Sigma", numResults, lowerGaussianSigma);
	setResult("Upper Gaussian Sigma", numResults, upperGaussianSigma);
	setResult("Will remove outliers", numResults, willRemoveOutliers);
	setResult("Threshold Algorithm", numResults, thresholdType);
	setResult("Maximum Filter radius", numResults, maximumFilterRadius);
	setResult("Minimum Filter radius", numResults, minimumFilterRadius);
	setResult("Used watershed?", numResults, isUsingWatershed);
	setResult("Nucleus count", numResults, nucleusCount);
}

	
function colourDeconvolution(windowName) {
	selectWindow(windowName);
	run("Colour Deconvolution", "vectors=[H DAB]");

	selectWindow("Colour Deconvolution");
	close();

	selectWindow(windowName+"-(Colour_1)");
	rename("H");
	selectWindow(windowName+"-(Colour_2)");
	rename("DAB");
	selectWindow(windowName+"-(Colour_3)");
	rename("Other");
}

function resetEnvironment() {
	closeAllWindows();
	run("Clear Results");
}

function closeAllWindows() {
	while (nImages>0) {
	  selectImage(nImages);
	  close();
	}
}
