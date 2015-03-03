dir = getDirectory("Choose a Directory");
countAllNucleiForDir(dir);

function countAllNucleiForDir(dir) {
	fileList = getFileList(dir)
	for (i = 0; i < fileList.length; ++i) {
		fileName = fileList[i];
		countAllNuclei(dir, fileName);
		closeAllWindows();
	}
}

function countAllNuclei(fileDirectory, fileName) {
	open(fileDirectory+fileName);
	colourDeconvolution(fileName);

	resetResults();
	result = countNuclei("H");
	print("Number of H nuclei in "+fileName+": "+result);

	resetResults();
	result = countNuclei("DAB");
	print("Number of DAB nuclei in "+fileName+": "+result);
}

function colourDeconvolution(windowName) {
	selectWindow(windowName);
	run("Colour Deconvolution", "vectors=[H DAB]");

	selectWindow("Colour Deconvolution");
	close();

	selectWindow(File.name+"-(Colour_1)");
	rename("H");
	selectWindow(File.name+"-(Colour_2)");
	rename("DAB");
	selectWindow(File.name+"-(Colour_3)");
	rename("Other");
}

//channelName should be H or DAB in this case
function countNuclei(channelName) {
	selectWindow(channelName);
	rename(channelName+"_channel");

	run("Duplicate...", "title="+channelName+"_channel_blur");
	selectWindow(channelName+"_channel_blur");
	run("Gaussian Blur...", "sigma=10");

	imageCalculator("Subtract create 32-bit", channelName+"_channel",channelName+"_channel_blur");

	selectWindow(channelName+"_channel");
	close();

	selectWindow(channelName+"_channel_blur");
	close();

	selectWindow("Result of "+channelName+"_channel");
	rename(channelName+"_binary_nucleuses");

	// now apply maximum and minimum filter
	run("Maximum...", "radius=3");
	run("Minimum...", "radius=3");

	run("8-bit");
	run("Triangle Algorithm");
	//setThreshold(174, 255);
	run("Make Binary", "thresholded remaining black");
	run("Invert");

	run("Watershed");
	run("Analyze Particles...", " ");

	return nResults;
}

function resetResults() {
	run("Clear Results");
}

function closeAllWindows() {
	while (nImages>0) {
	  selectImage(nImages);
	  close();
	}
}
