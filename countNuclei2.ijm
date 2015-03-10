if (nImages > 0 && !getBoolean("This script will remove all images from your session. Do you wish to continue?")) exit;

resetEnvironment();

//=== User Interface =======================================================================
open(File.openDialog("Choose a picture to open"));

Dialog.create("Nucleus Count Options");

Dialog.addChoice("Nucleus stain colour:", newArray("DAB", "H", "BOTH"));
Dialog.addNumber("Lower gaussian blur sigma:", 2);
Dialog.addNumber("Upper gaussian blur sigma:", 6);
Dialog.addCheckbox("Remove outliers:", true);
Dialog.addChoice("Threshold type:", newArray("yen", "triangle"));

Dialog.addNumber("Maximum filter radius:", 4);
Dialog.addNumber("Minimum filter radius:", 4);

Dialog.addCheckbox("Use Watershed", true);
Dialog.show();

nucleusColour = Dialog.getChoice();
lowerGaussianSigma = Dialog.getNumber();
upperGaussianSigma = Dialog.getNumber();
willRemoveOutliers = Dialog.getCheckbox();
thresholdType = Dialog.getChoice();
maximumFilterRadius = Dialog.getNumber();
minimumFilterRadius = Dialog.getNumber();
isUsingWatershed = Dialog.getCheckbox();

//=== Implementation ======================================================================

// Global variables

var initArraySize = 10000;
var nucleusColours = newArray(initArraySize);
var otherColours = newArray(initArraySize);
var lowerGaussianSigmas = newArray(initArraySize);
var upperGaussianSigmas = newArray(initArraySize);
var willRemoveOutlierss = newArray(initArraySize);
var thresholdTypes = newArray(initArraySize);
var maximumFilterRadiuses = newArray(initArraySize);
var minimumFilterRadiuses = newArray(initArraySize);
var isUsingWatersheds = newArray(initArraySize);
var nucleusCounts = newArray(initArraySize);
numIterations = calculateNumberIterations(nucleusColour); // calculate the number of times we're iterating over the countNuclei function


if (nucleusColour == "BOTH") {
	nucleusColoursToTest = newArray("H", "DAB");
	
} else if (nucleusColour == "H") {
	nucleusColoursToTest = newArray("H");
} else {
	nucleusColoursToTest = newArray("DAB");
}

for (nucleusColourIndex = 0; nucleusColourIndex < nucleusColoursToTest.length; nucleusColourIndex++) {
	resultIndex = nucleusColourIndex;


	nextNucleusColour = nucleusColoursToTest[nucleusColourIndex];
	countNuclei(nextNucleusColour, lowerGaussianSigma,
		upperGaussianSigma, willRemoveOutliers, thresholdType, maximumFilterRadius,
		minimumFilterRadius, isUsingWatershed, resultIndex);
}

// having looped through all the combinations, we now need to write all the results up in the results table
writeResultsToResultsTable();


function writeResultsToResultsTable() {
	run("Clear Results");

	for (i = 0; i < numIterations; ++i) {
		setResult("Nucleus Colour", i, nucleusColours[i]);
		setResult("Lower Gaussian Sigma", i, lowerGaussianSigmas[i]);
		setResult("Upper Gaussian Sigma", i, upperGaussianSigmas[i]);
		setResult("Will remove outliers", i, willRemoveOutlierss[i]);
		setResult("Threshold Algorithm", i, thresholdTypes[i]);
		setResult("Maximum Filter radius", i, maximumFilterRadiuses[i]);
		setResult("Minimum Filter radius", i, minimumFilterRadiuses[i]);
		setResult("Used watershed?", i, isUsingWatersheds[i]);
		setResult("Nucleus count", i, nucleusCounts[i]);
	}
}

/**
 * @param thresholdType can be value ["yen", "triangle"] 
 */
function countNuclei (nucleusColour,
	lowerGaussianSigma, upperGaussianSigma, willRemoveOutliers, thresholdType,
	maximumFilterRadius, minimumFilterRadius, isUsingWatershed, resultIndex) {

	otherColour = "";
	if (nucleusColour == "DAB") {
		otherColour = "H";
	} else {
		otherColour = "DAB";
	}


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
	writeResultsToArray(nucleusColour, otherColour,
		lowerGaussianSigma, upperGaussianSigma, willRemoveOutliers, thresholdType,
		maximumFilterRadius, minimumFilterRadius, isUsingWatershed, nucleusCount, resultIndex);


	return nucleusCount;
}

function writeResultsToArray(nucleusColour, otherColour, lowerGaussianSigma, upperGaussianSigma, willRemoveOutliers, thresholdType, maximumFilterRadius, minimumFilterRadius, isUsingWatershed, nucleusCount,arrayIndex) {
	nucleusColours[arrayIndex] = nucleusColour;
	otherColours[arrayIndex] = otherColour;
	lowerGaussianSigmas[arrayIndex] = lowerGaussianSigma;
	upperGaussianSigmas[arrayIndex] = upperGaussianSigma;
	willRemoveOutlierss[arrayIndex] = willRemoveOutliers;
	thresholdTypes[arrayIndex] = thresholdType;
	maximumFilterRadiuses[arrayIndex] = maximumFilterRadius;
	minimumFilterRadiuses[arrayIndex] = minimumFilterRadius;
	isUsingWatersheds[arrayIndex] = isUsingWatershed;
	nucleusCounts[arrayIndex] = nucleusCount;
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

function calculateNumberIterations(nucleusColour) {
	if (nucleusColour == "BOTH") {
		return 2;
	} else {
		return 1;
	}
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

function closeAllWindowsExcept(windowName) {
	for (i = 1; i < nImages; i++) {
		selectImage(i);
		imageTitle = getTitle();

		if (imageTitle != windowName) {
			close();
		}
	}
}
