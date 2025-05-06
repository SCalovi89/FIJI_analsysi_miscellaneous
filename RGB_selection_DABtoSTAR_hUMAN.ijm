///////author Stefano Calovi, 2024
//RGB counting of nuclei, inserting (human in the loop) roi, names etc, and filtering results via roimanager
////////assign area_ human in the loop

brainarea = getString("Type the area you want to measure, no spaces:", "eg: CA1_1");
//////GET INFO BRAIN ANALISED
resetMinAndMax();
title = getTitle()
title_without_extension = substring(title, 0, lengthOf(title)-4)

//ENHANCE AND DEHENANCE CONTRAST BEFORE AND AFTER ROIS

Property.set("CompositeProjection", "Sum");
Stack.setDisplayMode("composite");
Property.set("CompositeProjection", "null");
Stack.setDisplayMode("color");
Stack.setChannel(1);
setMinAndMax(255, 255);
Stack.setChannel(2);
setMinAndMax(161, 255);
Stack.setChannel(3);
setMinAndMax(187, 255);
Property.set("CompositeProjection", "Sum");
Stack.setDisplayMode("composite");

///MAKE ROI, SELECT ROI
setTool("polygon");
waitForUser("select roi with polygon, AREAS CAN NOT OVERLAP");

////DEHENCACER COLORS
Property.set("CompositeProjection", "null");
Stack.setDisplayMode("color");
Stack.setChannel(1);
resetMinAndMax();
Stack.setChannel(2);
resetMinAndMax();
Stack.setChannel(3);
resetMinAndMax();
Property.set("CompositeProjection", "Sum");
Stack.setDisplayMode("composite");

///CANCEL THE COUNTED AREA TO AVOID REPEAT IN THE FUTURE AND SEE LIMITS
Roi.setPosition(1);
roiManager("Add");

/////get area into a surface var
run("Set Measurements...", "area mean display redirect=None decimal=3");
run("Measure");
surface = getResult("Area");
run("Clear Results");
///before run, SELECT THE ROI TO COUNT
run("Duplicate...", "title=COUNTING duplicate");
/////////if a perfect square, skipt the following line
setBackgroundColor(0, 0, 0);
run("Clear Outside");
selectImage(title);
roiManager("Select", 0);
setBackgroundColor(0, 0, 0);
run("Clear", "slice");
roiManager("reset");

//WORK ON THE SELCTED AREA
selectImage("COUNTING");


////////CREATE STARDIST COMPATIBLE IMAGE

run("RGB Color");
run("8-bit");

/////////get background value EXCLUDING WHITE + SIGNAL (ADAPT SET THRESH)
run("Duplicate...", "title=bgmask duplicate");
setThreshold(179, 235, "raw");

setOption("BlackBackground", true);
run("Convert to Mask");
run("Create Selection");
roiManager("Add");
selectWindow("COUNTING (RGB)");
roiManager("Select", 0);
roiManager("measure");
BG = getResult("Mean");
//selectWindow("bgmask");
//run("Close");
roiManager("reset");
//////////////////////////////////////////////////////////////////////////////
// Get dimensions of the currently open image
selectWindow("COUNTING (RGB)");
getDimensions(width, height, channels, slices, frames);

// Create new blank image with the same dimensions
newImage("Blank Image", "8-bit black", width, height, channels, slices, frames);
setAutoThreshold("Default");
run("Convert to Mask");
// Create mask to count with STARDIST
imageCalculator("Subtract", "Blank Image","COUNTING (RGB)");
rename("stardist");
run("Subtract Background...", "rolling=100");

////BASAL STARDIST - probably to be changed
run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'stardist', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.1', 'percentileTop':'99.9', 'probThresh':'0.479071', 'nmsThresh':'0.3', 'outputType':'Both', 'nTiles':'2', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
wait(5000);
////////

////////////LOOP THROUGH ROI NMANAGER TO EXCLUDE FALSE POSITIVE
// Set initial parameters
minimum_size = 200;
maximum_size = 1200;
min_circ = 0.5;
run("Set Measurements...", "area mean shape display redirect=None decimal=3");
selectImage("COUNTING (RGB)");
// Initialize arrays to hold indices of ROIs to be deleted
to_be_deleted = newArray();

// Get the total number of ROIs
n = roiManager("count");

// Loop through each ROI
for (i = 0; i < n; i++) {
    roiManager("Select", i);
    
    // Check size condition
    getRawStatistics(nPixels, mean, min, max, std, histogram);
    if (nPixels <= minimum_size || nPixels > maximum_size) {
        to_be_deleted = Array.concat(to_be_deleted, i);
        continue; // Skip further checks for this ROI if size condition is met
    }
    ///EXCLUDE IF LOWER-EQUAL THAN BG
    getRawStatistics(nPixels, mean, min, max, std, histogram);
    if (mean <= BG) {
        to_be_deleted = Array.concat(to_be_deleted, i);
        continue; // Skip further checks for this ROI if size condition is met
    }
    
    // Check circularity condition
    run("Measure");
    circ = getResult("Circ.");
    if (circ <= min_circ) {
        to_be_deleted = Array.concat(to_be_deleted, i);
        continue; // Skip further checks for this ROI if circularity condition is met
    }
    
    // Check for black pixels
    getStatistics(area, mean, min, max, std, histogram);
    if (min <= 1) {
        to_be_deleted = Array.concat(to_be_deleted, i);
    }
}

// Delete all ROIs that failed any of the conditions
roiManager("Select", to_be_deleted);
roiManager("Delete");

////////////////NOW WE eliminated all incorrect rois

run("Clear Results");

/////////////end of loops

////clean before quantifying
run("Set Measurements...", "area mean display redirect=None decimal=3");
selectImage("stardist");
close();
selectImage("COUNTING");
close();
selectImage("Label Image");
close();
selectImage("COUNTING (RGB)");
roiManager("Show All");

/////////////////NOW THE ROI MANAGER CONTAINS PERFECT MASKS; INSERT HERE TO SAVE THE ROI SET.ZIP

///quantify over 8 bit file - fluo. simulation
roiManager("Measure");
/////MANUAL CHECKING:

selectWindow("bgmask");
print(BG);
waitForUser("is the bg ok??");

run("Close");

waitForUser("is the counting ok??");

///////////apply bg correction to the extracted values
pBG = 255 - BG;
n = getValue("results.count");
for (i = 0; i < n; i++) {
	orig = getResult("Mean", i);
	porig = 255 - orig; 
	corrected = porig - pBG;
	print(corrected);
	setResult("BG_corr", i, corrected);
}

//////////INSERT HERE YOUR PATHWAY!
//saveAs("Results", "F:/central_dread_behavior/c-fos_slidescanner/RESULTS/" + title_without_extension + "_" + brainarea + "_Results.csv");
//roiManager("Save", "F:/central_dread_behavior/c-fos_slidescanner/RESULTS/" + title_without_extension + "_" + brainarea + "_RoiSet.zip");

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
//////INSERT HERE YOUR PATHWAY
//saveAs("Text", "F:/central_dread_behavior/c-fos_slidescanner/RESULTS/" + title_without_extension + "_" + brainarea + "_dist.csv");
print("\\Clear");


////////here the saving path if wanted

//////////clean roi manager and everything for next slide
roiManager("reset");
//run("Close All");
run("Clear Results");

selectImage("BG_corr Distribution");
close();
selectImage("BG_corr Distribution");
close();
selectImage("COUNTING (RGB)");
close();
