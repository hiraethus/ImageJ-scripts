File.openDialog("Pick an image...go on!");
fileName = File.name;
open(File.directory+fileName);

colourDeconvolution(fileName);
countBlue("H");

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

function countBlue(windowName) {
	selectWindow(windowName);
	rename("blue_channel");

	run("Duplicate...", "title=blue_channel_blur");
	selectWindow("blue_channel_blur");
	run("Gaussian Blur...", "sigma=10");

	imageCalculator("Subtract create 32-bit", "blue_channel","blue_channel_blur");
	selectWindow("Result of blue_channel");
	rename("binary_nucleuses");

	// now apply maximum and minimum filter
	run("Maximum...", "radius=3");
	run("Minimum...", "radius=3");

	run("8-bit");
	run("Triangle Algorithm");
	//setThreshold(174, 255);
	run("Make Binary", "thresholded remaining black");
	run("Invert");

	run("Watershed");
	run("Analyze Particles...", "add");
}