// Prompt the user for the input directory
inputDir = getDirectory("Choose the directory where images are");
// Prompt the user for the output directory
outputDir = getDirectory("Choose the RESULTS directory");

// Get the list of all files in the input directory
fileList = getFileList(inputDir);

// Concatenate the file names into a single string
fileNamesString = "";
for (i = 0; i < fileList.length; i++) {
    fileNamesString += fileList[i] + "\n";
}

///cycle through the pics
num = 0;
for (q = 0; q < fileList.length; q++) {
	
	//prepare new cycle
	//calibration of this pics: 1.32 um per micron
	num = num + 1;
	roiManager("reset");
	run("Close All");
	run("Clear Results");
	print("\\Clear");
	
	//open target orig image
	fileName = fileList[q];
	inputPath = inputDir + fileName;
	fileNamewithout_exten =  substring(fileName, 0, lengthOf(fileName)-4);
	open(inputPath);

	roiManager("deselect");
	run("Duplicate...", "title=mask channels=1");
	setThreshold(0, 1, "raw");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Watershed");
	run("Analyze Particles...", "size=10-Infinity pixel show=Masks add");
	run("16-bit");
	n = roiManager('count');
	j=0;
	for (i = 0; i < n; i++) {
    	roiManager('select', i);
    	// process roi here
    	j = j+1;
    	changeValues(0,255,j);
	}
	saveAs("Tiff", outputDir + fileName + "/training00"+ num +".tif");
}	
