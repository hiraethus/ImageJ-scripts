DEBUG = false;
BATCH_MODE = true;

if (nImages > 0) {
	if (!getBoolean("This script will remove all images from your session. Do you wish to continue?")) exit;
}

resetEnvironment();

//=== User Interface =======================================================================
dir = getDirectory("Choose a Directory");
fileList = getFileList(dir);

Dialog.create("Nucleus Count Options");

Dialog.addMessage("Images to examine:");

for (i = 0; i < fileList.length; ++i) {
	Dialog.addCheckbox(fileList[i], true);
}
Dialog.addMessage("---");

Dialog.addChoice("Nucleus stain colour:", newArray("BOTH", "DAB", "H"));
Dialog.addSlider("Gaussian blur sigma", 0, 30, 15);
Dialog.addCheckbox("Remove outliers:", true);
Dialog.addChoice("Threshold type:", newArray("yen", "triangle"));

Dialog.addSlider("Maximum filter radius:", 0, 10, 4);
Dialog.addSlider("Minimum filter radius:", 0, 10, 4);

Dialog.addCheckbox("Use Watershed", true);
Dialog.addMessage("---");
Dialog.addCheckbox("Save output images?", false);
Dialog.show();

// build the list of files we want to include
selectedFileNames = "";
for (i = 0; i < fileList.length; ++i) {
	isIthSelected = Dialog.getCheckbox();
	if (isIthSelected) {
		selectedFileNames += fileList[i] +";";
	}
}
if(endsWith(selectedFileNames, ";")) {
	lastIndex = lengthOf(selectedFileNames) - 1;
	selectedFileNames = substring(selectedFileNames, 0, lastIndex);
}

fileList = split(selectedFileNames, ";");

nucleusColour = Dialog.getChoice();
upperGaussianSigma = Dialog.getNumber();
willRemoveOutliers = Dialog.getCheckbox();
thresholdType = Dialog.getChoice();
maximumFilterRadius = Dialog.getNumber();
minimumFilterRadius = Dialog.getNumber();
isUsingWatershed = Dialog.getCheckbox();

isSaveOutputImages = Dialog.getCheckbox();
outputDir = "/";
if (isSaveOutputImages) {
	outputDir = getDirectory("Choose a Directory");
}

//=== Implementation ======================================================================

// Global variables

var initArraySize = 10000;
var filenames = newArray(initArraySize);
var nucleusColours = newArray(initArraySize);
var otherColours = newArray(initArraySize);
var upperGaussianSigmas = newArray(initArraySize);
var willRemoveOutlierss = newArray(initArraySize);
var thresholdTypes = newArray(initArraySize);
var maximumFilterRadiuses = newArray(initArraySize);
var minimumFilterRadiuses = newArray(initArraySize);
var isUsingWatersheds = newArray(initArraySize);
var nucleusCounts = newArray(initArraySize);
numIterations = calculateNumberIterations(nucleusColour, fileList.length); // calculate the number of times we're iterating over the countNuclei function


if (nucleusColour == "BOTH") {
	nucleusColoursToTest = newArray("H", "DAB");
	
} else if (nucleusColour == "H") {
	nucleusColoursToTest = newArray("H");
} else {
	nucleusColoursToTest = newArray("DAB");
}

if (BATCH_MODE) setBatchMode(true);
count = 0;
for (fileIndex = 0; fileIndex < fileList.length; ++fileIndex) {

	for (nucleusColourIndex = 0; nucleusColourIndex < nucleusColoursToTest.length; nucleusColourIndex++) {

		open(dir+fileList[fileIndex]);

		nextNucleusColour = nucleusColoursToTest[nucleusColourIndex];
		countNuclei(File.name, nextNucleusColour,
			upperGaussianSigma, willRemoveOutliers, thresholdType, maximumFilterRadius,
			minimumFilterRadius, isUsingWatershed, count);

			clearRoiManager();
			Overlay.remove ();
			count++;

		closeAllWindowsExceptFlattenedROI();

	}
}
if (BATCH_MODE) setBatchMode("exit and display");
// having looped through all the combinations, we now need to write all the results up in the results table
writeResultsToResultsTable();
run("Tile");

function writeResultsToResultsTable() {
	run("Clear Results");

	for (i = 0; i < numIterations; ++i) {
		setResult("Image", i, filenames[i]);
		setResult("Nucleus Colour", i, nucleusColours[i]);
		setResult("Gaussian Sigma", i, upperGaussianSigmas[i]);
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
function countNuclei (filename, nucleusColour,
	upperGaussianSigma, willRemoveOutliers, thresholdType,
	maximumFilterRadius, minimumFilterRadius, isUsingWatershed, resultIndex) {
	numberOfSteps = 14;

	debug("countNuclei("+filename+", "+nucleusColour
		+ ", "+upperGaussianSigma+", "+willRemoveOutliers+", "+thresholdType+", "+maximumFilterRadius
		+ ", "+minimumFilterRadius+", "+isUsingWatershed+", "+resultIndex+")");

	otherColour = "";
	if (nucleusColour == "DAB") {
		otherColour = "H";
	} else {
		otherColour = "DAB";
	}
	updateProgressBar(resultIndex, numIterations, 1/numberOfSteps);
	
	selectWindow (filename);
	colourDeconvolution (filename);
	
	selectWindow (nucleusColour);
	run("Duplicate...", "title="+nucleusColour+"_Duplicate");
	
	selectWindow (nucleusColour+"_Duplicate");
	run("Gaussian Blur...", "sigma="+upperGaussianSigma);
	rename(nucleusColour+"_Gaussian_upper");
	updateProgressBar(resultIndex, numIterations, 3/numberOfSteps);
	
	imageCalculator("Subtract create 32-bit", nucleusColour, nucleusColour+"_Gaussian_upper");
	updateProgressBar(resultIndex, numIterations, 4/numberOfSteps);

	selectWindow ("Result of "+nucleusColour);
	rename(nucleusColour+"_sum_of_Gaussian");
	
	selectWindow (nucleusColour+"_sum_of_Gaussian");

	updateProgressBar(resultIndex, numIterations, 5/numberOfSteps);
	updateProgressBar(resultIndex, numIterations, 7/numberOfSteps);
	
	//selectWindow (nucleusColour+"_sum_of_Gaussian_AND_other_Minus_"+otherColour);
	// look at this bit - might need changed 
	run("Maximum...", "radius="+maximumFilterRadius);
	updateProgressBar(resultIndex, numIterations, 8/numberOfSteps);

	run("Minimum...", "radius="+minimumFilterRadius);
	updateProgressBar(resultIndex, numIterations, 9/numberOfSteps);

	if (thresholdType == "yen") {
		setAutoThreshold("Yen dark");
	} else if (thresholdType == "triangle") {
		run("8-bit");
		run("Triangle Algorithm");
	}
	updateProgressBar(resultIndex, numIterations, 10/numberOfSteps);
	//run("Threshold...");
	
	run("Make Binary", "thresholded remaining black");

	run("Invert");
//// Now for other colour //////////////////////////////////////////
	if (otherColour == "DAB") {
		run("Divide...", "value=255.000");

		selectWindow (otherColour);
		run("Duplicate...", "title="+otherColour+"_Duplicate");

		selectWindow (otherColour+"_Duplicate");
		run("Gaussian Blur...", "sigma="+upperGaussianSigma);
		rename(otherColour+"_Gaussian_upper");
		updateProgressBar(resultIndex, numIterations, 3/numberOfSteps);

		imageCalculator("Subtract create 32-bit", otherColour, otherColour+"_Gaussian_upper");
		updateProgressBar(resultIndex, numIterations, 4/numberOfSteps);

		selectWindow ("Result of "+otherColour);
		rename(otherColour+"_sum_of_Gaussian");

		selectWindow (otherColour+"_sum_of_Gaussian");

		updateProgressBar(resultIndex, numIterations, 5/numberOfSteps);
		updateProgressBar(resultIndex, numIterations, 7/numberOfSteps);

		//selectWindow (nucleusColour+"_sum_of_Gaussian_AND_other_Minus_"+otherColour);
		// look at this bit - might need changed
		run("Maximum...", "radius="+maximumFilterRadius);
		updateProgressBar(resultIndex, numIterations, 8/numberOfSteps);

		run("Minimum...", "radius="+minimumFilterRadius);
		updateProgressBar(resultIndex, numIterations, 9/numberOfSteps);

		if (thresholdType == "yen") {
			setAutoThreshold("Yen dark");
		} else if (thresholdType == "triangle") {
			run("8-bit");
			run("Triangle Algorithm");
		}
		updateProgressBar(resultIndex, numIterations, 10/numberOfSteps);
		run("Make Binary", "thresholded remaining black");

		run("Invert");
		run("Divide...", "value=255.000");
	///////////////////////////////////////////////////////////////
		imageCalculator("Multiply create 32-bit", nucleusColour+"_sum_of_Gaussian", otherColour+"_sum_of_Gaussian");
		rename(nucleusColour+"_"+otherColour+"_difference");


		imageCalculator("Subtract create 32-bit", nucleusColour+"_sum_of_Gaussian", nucleusColour+"_"+otherColour+"_difference");

		run("8-bit");
	}

	// maybe need to change this bit
	if (willRemoveOutliers) {
		run("Remove Outliers...", "radius=4 threshold=50 which=Dark");
	}


	if (isUsingWatershed) {
		run("Watershed");
	}

	updateProgressBar(resultIndex, numIterations, 11/numberOfSteps);

	run("Clear Results");
	clearRoiManager();
	updateProgressBar(resultIndex, numIterations, 12/numberOfSteps);

	run("Analyze Particles...", "add");
	nucleusCount = roiManager("count");
	updateProgressBar(resultIndex, numIterations, 13/numberOfSteps);

	combineRegionsOfInterestAndApplyToFile("ROI_"+nucleusColour+"_"+filename);
	updateProgressBar(resultIndex, numIterations, 14/numberOfSteps);

	writeResultsToArray(filename, nucleusColour, otherColour,
		upperGaussianSigma, willRemoveOutliers, thresholdType,
		maximumFilterRadius, minimumFilterRadius, isUsingWatershed, nucleusCount, resultIndex);


	return nucleusCount;
}

function updateProgressBar(fullImagesComplete, totalImages, countNucleiFraction) {
	showProgress((fullImagesComplete/totalImages) + (countNucleiFraction*1/numIterations));
}

function combineRegionsOfInterestAndApplyToFile(outputFilename) {
	mergeAllROIs();
	roiManager("Set Color", "green");

	selectWindow(filename);
	run("Duplicate...", "title="+filename+"_duplicate");

	roiManager("Select", 0);
	run("Add Selection...");
	run("Flatten");

	// will have opened a new window. Let's change its name
	rename(outputFilename);
	if (isSaveOutputImages) {
		saveAs("png", outputDir+outputFilename);
	}

	selectWindow(filename+"_duplicate");
	close();
}


function writeResultsToArray(filename, nucleusColour, otherColour, upperGaussianSigma, willRemoveOutliers, thresholdType, maximumFilterRadius, minimumFilterRadius, isUsingWatershed, nucleusCount,arrayIndex) {
	filenames[arrayIndex] = filename;
	nucleusColours[arrayIndex] = nucleusColour;
	otherColours[arrayIndex] = otherColour;
	upperGaussianSigmas[arrayIndex] = upperGaussianSigma;
	willRemoveOutlierss[arrayIndex] = willRemoveOutliers;
	thresholdTypes[arrayIndex] = thresholdType;
	maximumFilterRadiuses[arrayIndex] = maximumFilterRadius;
	minimumFilterRadiuses[arrayIndex] = minimumFilterRadius;
	isUsingWatersheds[arrayIndex] = isUsingWatershed;
	nucleusCounts[arrayIndex] = nucleusCount;
}

function clearRoiManager() {
	//delete them all!
	if (roiManager("count") > 0) {
		roiManager("Deselect");
		roiManager("Delete");
	}
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

function calculateNumberIterations(nucleusColour, numImages) {
	iters = 0;
	if (nucleusColour == "BOTH") {
		iters += 2;
	} else {
		iters += 1;
	}

	return iters * numImages;
}

function resetEnvironment() {
	closeAllWindows();
	clearRoiManager();
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

function closeAllWindowsExceptFlattenedROI() {
	imageIDs = getImageIDs();
	for (i = 0; i < imageIDs.length; ++i) {
		selectImage(imageIDs[i]);
		imageTitle = getTitle();
		if (!startsWith(imageTitle, "ROI")) {
			close();
		}
	}
}

function getImageIDs() {
	imageIDs = newArray(nImages);
	for (i = nImages; i > 0; i--) {
		selectImage(i);
		imageIDs[i - 1] = getImageID();
	}

	return imageIDs;
}

// novel way to merge all ROIs so that ImageJ doesn't crash
function mergeAllROIs() {
	indexes = newArray(0, 1);
	while (roiManager("count") > 1) {
		roiManager("select", indexes);
		roiManager("Combine");
		roiManager("Add");
		roiManager("Delete");
	}
}

function debug(string) {
	if (DEBUG == true) {
		print(string);
	}
}