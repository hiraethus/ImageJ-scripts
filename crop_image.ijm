// crop region in centre of image 500px X 500px
cropWidth = 500;
cropHeight = 500;

x = (getWidth() / 2) - (cropWidth / 2);
y = (getHeight() / 2) - (cropHeight / 2);

makeRectangle(x, y, cropWidth, cropHeight);
run("Crop");
