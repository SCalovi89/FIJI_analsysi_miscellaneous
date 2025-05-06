/////DABtoSTAR_hNC. author: Stefano Calovi; 07 april 2024.
///VERSION DAB ALREADY 8 BIT
// FAST INTRO MESSAGE

waitForUser("WELCOME to DABtoSTAR_hNC!\nThis macro uses the STARDIST 2D fluorescent nuclear counter to count nuclear markers and extract their intensity values, with and without considering the background value.\n\nThe idea is to quantify cells from in large images which have been mapped beforehand, and the maps stored as roi managers.\n\nThe script is optimised for 20X magnification bright-field pictures taken with a slide scanner, where the surface of a cell goes between 400 to 1200 square pixels.\n\nThe macro asks you to choose a directory where are stored the images to analyse, the files needs to be saved with the format  name.tiff \n\nThrefore will ask you to choose the directory where are stored the corresponding ROI manager maps, which must have the default name as name_RoiSet.zip.,\n\nEventually it will ask you to choose a Results directory.,\n\nThe macro is a human-in-the-loop program where the macro will loop through the areas mapped, asking which is the name of the analysed area,\n\nand ask whether the background and counting is ok by showing the resulting masks,\n\It will produce in the result folder 3 files, the roimanager of the extrapolated roi with the counted neurons, the corresponding values of area, MGV, and the background subtracted MGV values into csv files.\n\nEventually saves the results of the distribution plot with the value of the surface of the roi in another csv file called dist.");

// Prompt the user for the input directory
inputDir = getDirectory("Choose the directory where images are");
inputRoiDir = getDirectory("Choose the directory where are maps on brain are\n\nthe file has to end in _RoiSet.zip");

// Get the list of all files in the input directory
fileList = getFileList(inputDir);

// Concatenate the file names into a single string
fileNamesString = "";
for (i = 0; i < fileList.length; i++) {
    fileNamesString += fileList[i] + "\n";
}

// Display the file names in a dialog window
showMessage("Choose AN IMAGE from this File List", fileNamesString);

// Prompt the user for the file name
fileName = getString("Enter the image name without extension .tif", "");
// Append the file extension to the file name
fileRoiNameWithExtension = fileName + "_RM_.zip";
fileNameWithExtension = fileName + ".tif";

// Prompt the user for the output directory
outputDir = getDirectory("Choose the RESULTS directory");

//print("Input Directory: " + inputDir);
//print("Output Directory: " + outputDir);
//print("File Name: " + fileNameWithExtension);
//print("Full Input Path: " + inputPath);
//print("Full Output Path: " + outputPath);

inputPath = inputDir + fileNameWithExtension;
inputRoiPath = inputRoiDir + fileRoiNameWithExtension
outputPath = outputDir;

///OPEN WINDOW TO COUNT and make it fit with the roi designed (eg. if are upside down like here)
open(inputPath);
//run("Flip Vertically");//MY IMAGES ARE UPSIDE DOWN, CAREFUL HERE
roiManager("Open", inputRoiPath);

nareas = roiManager("count");

for (i = 0; i < nareas; i++) {
	selectImage(fileNameWithExtension);
	roiManager("reset");
	roiManager("Open", inputRoiPath);
    roiManager('select', i);
    //run("Duplicate...", "duplicate");
//    run("Duplicate...", "title=" fileNameWithExtension + "_c duplicate");
    //////////////DABtoSTAR
    
    
////////assign area_ human in the loop

	brainarea = getString("Type the name of the area you are measuring, no spaces:", "eg: CA1_1");
//////GET INFO BRAIN ANALISED
	resetMinAndMax();
	title = getTitle();
	title_without_extension = substring(title, 0, lengthOf(title)-4);

/////get area into a surface var
	run("Set Measurements...", "area mean display redirect=None decimal=3");
	run("Measure");
	surface = getResult("Area");
	run("Clear Results");
///before run, SELECT THE ROI TO COUNT
	run("Duplicate...", "title=COUNTING duplicate");
/////CLEAN ROI MANAGER TO AVOID CONFUSION

/////////if a perfect square, skipt the following line
	setBackgroundColor(0, 0, 0);
	run("Clear Outside");

//////MARKING THE ALREADY DONE ROIS, NOT NECESSARY HERE
//selectImage(title);
//roiManager("Select", 0);
//setBackgroundColor(0, 0, 0);
//run("Clear", "slice");  //WITH PREDONE ROIS NO NECESSARY TO CLEAN
	roiManager("reset");

//WORK ON THE SELCTED AREA
	selectImage("COUNTING");


////////CREATE STARDIST COMPATIBLE IMAGE from DAB image

	//run("RGB Color");
	run("8-bit");

/////////get background value EXCLUDING WHITE + SIGNAL (ADAPT SET THRESH)
	run("Duplicate...", "title=bgmask duplicate");
	setThreshold(140, 215, "raw");
	run("Threshold...");
	waitForUser("now you can modify the threshold values to get the bg; the values till now a 140 to 215");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Create Selection");
	roiManager("Add");
	selectWindow("COUNTING");
	roiManager("Select", 0);
	roiManager("measure");
	BG = getResult("Mean");
	//selectWindow("bgmask");
	//run("Close");
	roiManager("reset");
/////////////////////inversion, necessary for DAB //////////////////////

// Get dimensions of the currently open image
	selectWindow("COUNTING");
	getDimensions(width, height, channels, slices, frames);

// Create new blank image with the same dimensions
	newImage("Blank Image", "8-bit black", width, height, channels, slices, frames);
	setAutoThreshold("Default");
	run("Convert to Mask");
// Create mask to count with STARDIST
	imageCalculator("Subtract", "Blank Image","COUNTING");
	
/////////end of the subtraction for dab staining	
	rename("stardist");
	run("Subtract Background...", "rolling=100");

////BASAL STARDIST RUN - probably to be changed according to different pics
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'stardist', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.1', 'percentileTop':'99.9', 'probThresh':'0.479071', 'nmsThresh':'0.3', 'outputType':'Both', 'nTiles':'2', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	wait(5000);
////////

////////////LOOP THROUGH ROI NMANAGER TO EXCLUDE FALSE POSITIVE
// Set initial parameters
	minimum_size = 200;
	maximum_size = 1200;
	min_circ = 0.5;
	run("Set Measurements...", "area mean shape display redirect=None decimal=3");
	selectImage("COUNTING");
// Initialize arrays to hold indices of ROIs to be deleted
	to_be_deleted = newArray();

// Get the total number of ROIs
	n = roiManager("count");

// Loop through each ROI
	for (j = 0; j < n; j++) {
	    roiManager("Select", j);
	    
	    // Check size condition
	    getRawStatistics(nPixels, mean, min, max, std, histogram);
	    if (nPixels <= minimum_size || nPixels > maximum_size) {
	        to_be_deleted = Array.concat(to_be_deleted, j);
	        continue; // Skip further checks for this ROI if size condition is met
	    }
    
    // Check circularity condition
	    run("Measure");
	    circ = getResult("Circ.");
	    if (circ <= min_circ) {
	        to_be_deleted = Array.concat(to_be_deleted, j);
	        continue; // Skip further checks for this ROI if circularity condition is met
	    }
    
    // Check for black pixels
	    getStatistics(area, mean, min, max, std, histogram);
	    if (min <= 1) {
	        to_be_deleted = Array.concat(to_be_deleted, j);
	    }
	}

// Delete all ROIs that failed any of the conditions
	roiManager("Select", to_be_deleted);
	roiManager("Delete");
	run("Clear Results");

////////////////NOW WE eliminated all incorrect rois
/////////////end of loops

////clean before quantifying
	run("Set Measurements...", "area mean display redirect=None decimal=3");
	selectImage("stardist");
	close();

	selectImage("Label Image");
	close();

///quantify over 8 bit file - fluo. simulation

	selectImage("COUNTING");
	roiManager("Show All");

	roiManager("Measure");
/////MANUAL CHECKING:

	selectWindow("bgmask");
	print(BG);
	waitForUser("is the bg ok??");
	selectWindow("bgmask");
	run("Close");

	waitForUser("is the counting ok??");

///////////apply bg correction to the extracted values;
////only for dab
	pBG = 255 - BG;
	n = getValue("results.count");
	for (j = 0; j < n; j++) {
		orig = getResult("Mean", j);
		porig = 255 - orig; 
		corrected = porig - pBG;
		print(corrected);
		setResult("BG_corr", j, corrected);
	}

	saveAs("Results", outputPath + title_without_extension + "_" + brainarea + "_Results.csv");
	roiManager("Save", outputPath + title_without_extension + "_" + brainarea + "_RoiSet.zip");

	run("Distribution...", "parameter=BG_corr or=10 and=0-255");
////////run and save histogram
	selectWindow("Log");
	print("\\Clear");
	print("Area of: ," + surface);
	run("Distribution...", "parameter=BG_corr or=10 and=0-255");
//selectImage("BG_corr Distribution");
	selectWindow("BG_corr Distribution");
	Plot.getValues(bins, counts);
	Array.print (bins);
	Array.print (counts);

	selectWindow("Log");
	saveAs("Text", outputPath + title_without_extension + "_" + brainarea + "_dist.csv");
	print("\\Clear");

//////////clean roi manager and everything for next slide
//run("Close All");
	run("Clear Results");

	selectImage("BG_corr Distribution");
	close();
	selectImage("BG_corr Distribution");
	close();
	selectImage("COUNTING");
	close();
    
    roiManager("reset");

}

print(nareas);
waitForUser("Run the macro again quantify the next big picture");