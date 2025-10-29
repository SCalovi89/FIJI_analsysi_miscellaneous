// ===========================================
//Stefano Calovi + chatgtp, 291025;
//macro for human-in-the-loop quantification of cell from lif file
// AUTO-OPEN .LIF SERIES ONE-BY-ONE (FILTERED)
// corrected index sync (Bio-Formats offset)
// ===========================================
run("Close All");
// Create table and headers (only once)
if (isOpen("CellCOUNT_results") == 0) {
    Table.create("CellCOUNT_results");
    // header row index 0
    Table.set("Name", 0, "Name");
    Table.set("Area", 0, "Area");
    Table.set("Surface", 0, "Surface"); 
    Table.set("Tot Vol (um3)", 0, "Tot Vol (um3)");
    Table.set("DAPI nr.", 0, "DAPI nr.");
    Table.set("C2 nr.", 0, "C2 nr.");
    Table.set("C3 nr.", 0, "C3 nr.");
}

// Ask for the .lif file
lifPath = File.openDialog("Select .lif file");

// --- initialize Bio-Formats ---
// --- load series names once before any image processing ---
run("Bio-Formats Macro Extensions");
Ext.setId(lifPath);
Ext.getSeriesCount(seriesCount);
seriesNames = newArray(seriesCount);
for (k = 0; k < seriesCount; k++) {
    Ext.setSeries(k);
    Ext.getSeriesName(seriesNames[k]);
}

// --- define substrings of interest ---
substrings = newArray("cc", "ca1", "str");

print("Found " + seriesCount + " image series in file.");

// --- loop over series ---
for (i = 0; i < seriesCount; i++) {
	setBatchMode(false);
	run("Close All");
	// Initialize CLIJ2 only once
	run("CLIJ2 Macro Extensions", "cl_device=[NVIDIA GeForce RTX 3060]");
	Ext.CLIJ2_clear();

    // get series name (0-based)
    seriesName = seriesNames[i];
	seriesName_lc = toLowerCase(seriesName);

    // check if series name contains any desired substring
    match = false;
    for (s = 0; s < substrings.length; s++) {
        if (indexOf(seriesName_lc, substrings[s]) >= 0) {
            match = true;
            break;
        }
    }

    if (!match) {
        print("Skipping series " + i + " (" + seriesName + ")");
        continue; // go to next
    }

    // NOTE: Bio-Formats Importer uses 1-based index for series
    series_to_open = i + 1;

    print("Opening series " + i + " (" + seriesName + ")");

    run("Bio-Formats Importer", "open=[" + lifPath + "] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_" + series_to_open);

	roiManager("reset");
	title = getTitle();
	rename("anal_");
	run("Split Channels");

	//1. biscuit
	selectImage("C2-anal_");
	run("Duplicate...", "title=biscuit duplicate");
	//run("Subtract Background...", "rolling=50 stack");
	setThreshold(0, 12, "raw");
	setOption("BlackBackground", true);
	run("Convert to Mask", "background=Dark black");
	run("Smooth (3D)", "method=Gaussian sigma=1.000 use");
	setThreshold(150, 255, "raw");
	run("Convert to Mask", "background=Dark black");
	run("Median...", "radius=5 stack");
	run("Fill Holes", "stack");
	run("Analyze Particles...", "size=1000-Infinity pixel show=Masks stack");
	selectImage("biscuit");
	close;
	selectImage("Smoothed");
	close;
	selectImage("Mask of Smoothed");
	rename("biscuit");
	////////////

	//2. rois
	run("Merge Channels...", "c1=C1-anal_ c2=C2-anal_ c3=C3-anal_ create");
	selectImage("anal_");
	run("Subtract Background...", "rolling=50 stack");
	setSlice(6);
	setTool("polygon");

    // Ask the user how many ROIs are visible
    roi_to_cycle = getNumber("How many ROIs do you see in \"" + seriesName + "\" ?", 0);

    // skip this image if user entered 0
    if (roi_to_cycle == 0) {
        close();
        print("Skipped due to low quality or no ROIs.");
        continue;
    }

    // loop over each ROI to be drawn
    for (r = 1; r <= roi_to_cycle; r++) {
		run("CLIJ2 Macro Extensions", "cl_device=[NVIDIA GeForce RTX 3060]");
		Ext.CLIJ2_clear();
    	
    	selectImage("anal_");
        waitForUser("Draw ROI #" + r + " then click OK");

        // ask for sub-area name
        sub_area = getString("Enter sub_area name for ROI #" + r + ":", "none");
		run("Measure");
		surface_roi = getResult("Area");
		run("Clear Results");
		roiManager("add");
		run("Duplicate...", "title=anal_sm duplicate");
		run("Clear Outside");
		run("Split Channels");

		//calc volume
		selectImage("biscuit");
		roiManager("Select", 0);
		run("Duplicate...", "title=biscuit_sm duplicate");
		run("Clear Outside", "stack");
		run("Fill Holes", "stack");
		run("3D Volume");
		if (nResults > 1) {
			run("Summarize");
			to_go = nResults-4;
			vol_mean_roi = getResult("Volume(unit)", to_go);
			vol_roi = vol_mean_roi*(to_go);
		
		} else { 
			vol_roi = getResult("Volume(unit)");
		}

		//print(vol_roi);
		run("Clear Results");

		//////////counting cells///////////////////////////////////////////////////////
		dapi = counting_dapi("C1-anal_sm");
		selectImage("Label Image");
		rename("dapi_label");
		run("CLIJ2 Macro Extensions", "cl_device=[NVIDIA GeForce RTX 3060]");
		Ext.CLIJ2_clear();

		c2_count = counting_cells("C2-anal_sm");
		selectImage("Label Image");
		rename("c2_label");
		run("CLIJ2 Macro Extensions", "cl_device=[NVIDIA GeForce RTX 3060]");
		Ext.CLIJ2_clear();

		c3_count = counting_cells("C3-anal_sm");
		selectImage("Label Image");
		rename("c3_label");
		run("CLIJ2 Macro Extensions", "cl_device=[NVIDIA GeForce RTX 3060]");
		Ext.CLIJ2_clear();
		
		run("Merge Channels...", "c1=c2_label c2=c3_label c3=dapi_label create");
		selectImage("Composite");
		//rename(title+"_counting");
		//waitForUser("I WILL PRINT THIS COUNTING AND THROW IT, if not ok appoint it on paper");
		selectImage("Composite");
		saveAs("Tiff", "D:/Stefano/gfpANDcno_issue/2022_apc_gfp/counting/"+title+"_"+sub_area+"_result.tif");
		close;
		
		//print in specific place
		// === Append one row for this iteration ===
		row = Table.size("CellCOUNT_results"); // next free row index
		Table.set("Name", row, title);
		Table.set("Area", row, sub_area);
		Table.set("Surface", row, surface_roi);
		Table.set("Tot Vol (um3)", row, vol_roi);
		Table.set("DAPI nr.", row, dapi);
		Table.set("C2 nr.", row, c2_count);
		Table.set("C3 nr.", row, c3_count);
		// Refresh display
		Table.update("CellCOUNT_results");

		//.last. clean
		selectImage("C2-anal_sm");
		close;
		selectImage("C3-anal_sm");
		close;
		selectImage("C1-anal_sm");
		close;
		selectImage("biscuit_sm");
		close;

    }

}
print("finished all the files!");



/////////////////////////////////////////////////////////
function counting_cells(image) {
	setBatchMode(true);
	selectImage(image);
	//run("CLIJ2 Macro Extensions", "cl_device=[NVIDIA GeForce RTX 3060]");

	// extended depth of focus sobel projection
	image1 = image;
	Ext.CLIJ2_push(image1);
	image2 = "extended_1";
	sigma = 10.0;
	Ext.CLIJ2_extendedDepthOfFocusSobelProjection(image1, image2, sigma);
	Ext.CLIJ2_pull(image2);

	////
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'extended_1', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.479071', 'nmsThresh':'0.3', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

	selectImage("Label Image");
	setAutoThreshold("Default dark no-reset");
	setThreshold(1, 65535, "raw");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	////////////LOOP THROUGH ROI MANAGER TO EXCLUDE FALSE POSITIVE

	// Set initial parameters (opixels
	minimum_size = 28;
	maximum_size = 280;
	min_circ = 0.5;
	cf_BG = 0; //insert the background value (suggestion: in 8-bit) of the cfos staining.
	run("Set Measurements...", "area mean shape display redirect=None decimal=3");

	// Initialize arrays to hold indices of ROIs to be deleted
	to_be_deleted = newArray();

	if (roiManager("count")==0) {
		n_rois = 0;
	} else {	
		n_rois = roiManager("count");
	}

	// Loop through each ROI
	for (j = 0; j < n_rois; j++) {
		selectImage(image);
	    roiManager("Select", j);
	    
	    // Check size condition
	    getRawStatistics(nPixels, mean, min, max, std, histogram);
	    if (nPixels <= minimum_size || nPixels > maximum_size) {
	        to_be_deleted = Array.concat(to_be_deleted, j);
        	selectImage("Label Image");
        	roiManager("Select", j);
			run("Clear", "slice");
	        continue; // Skip further checks for this ROI if size condition is met
	    }
    
    	// Check circularity condition
	    run("Measure");
	    circ = getResult("Circ.");
	    if (circ <= min_circ) {
	        to_be_deleted = Array.concat(to_be_deleted, j);
	        selectImage("Label Image");
	        roiManager("Select", j);
			run("Clear", "slice");
	        continue; // Skip further checks for this ROI if circularity condition is met
	    }
	    
		run("Clear Results");
	}

	// Delete all ROIs that failed any of the conditions
	roiManager("Select", to_be_deleted);
	roiManager("Delete");
	run("Clear Results");

	
	selectImage("extended_1");
	close;
	
	fin_counting = roiManager("count");
	roiManager("reset");
	
	return fin_counting;
}
////////////////////////////////////////////

/////////////////////////////////////////////////////////
function counting_dapi(image) {
	setBatchMode(true);
	selectImage(image);
	//run("CLIJ2 Macro Extensions", "cl_device=[NVIDIA GeForce RTX 3060]");

	// extended depth of focus sobel projection
	image1 = image;
	Ext.CLIJ2_push(image1);
	image2 = "extended_1";
	sigma = 10.0;
	Ext.CLIJ2_extendedDepthOfFocusSobelProjection(image1, image2, sigma);
	Ext.CLIJ2_pull(image2);

	////
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'extended_1', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.479071', 'nmsThresh':'0.3', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

	selectImage("Label Image");
	setAutoThreshold("Default dark no-reset");
	setThreshold(1, 65535, "raw");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	////////////LOOP THROUGH ROI MANAGER TO EXCLUDE FALSE POSITIVE

	// Set initial parameters (opixels
	minimum_size = 35;
	maximum_size = 400;
	min_circ = 0.5;
	cf_BG = 0; //insert the background value (suggestion: in 8-bit) of the cfos staining.
	run("Set Measurements...", "area mean shape display redirect=None decimal=3");

	// Initialize arrays to hold indices of ROIs to be deleted
	to_be_deleted = newArray();

	if (roiManager("count")==0) {
		n_rois = 0;
	} else {	
		n_rois = roiManager("count");
	}

	// Loop through each ROI
	for (j = 0; j < n_rois; j++) {
		selectImage(image);
	    roiManager("Select", j);
	    
	    // Check size condition
	    getRawStatistics(nPixels, mean, min, max, std, histogram);
	    if (nPixels <= minimum_size || nPixels > maximum_size) {
	        to_be_deleted = Array.concat(to_be_deleted, j);
        	selectImage("Label Image");
        	roiManager("Select", j);
			run("Clear", "slice");
	        continue; // Skip further checks for this ROI if size condition is met
	    }
    
    	// Check circularity condition
	    run("Measure");
	    circ = getResult("Circ.");
	    if (circ <= min_circ) {
	        to_be_deleted = Array.concat(to_be_deleted, j);
	        selectImage("Label Image");
	        roiManager("Select", j);
			run("Clear", "slice");
	        continue; // Skip further checks for this ROI if circularity condition is met
	    }
	    
		run("Clear Results");
	}

	// Delete all ROIs that failed any of the conditions
	roiManager("Select", to_be_deleted);
	roiManager("Delete");
	run("Clear Results");
	selectImage("extended_1");
	close;
	if (roiManager("count")==0) {
		fin_counting = 0;
	} else {	
		fin_counting = roiManager("count");
		roiManager("reset");
	}	
	
	return fin_counting;
}
////////////////////////////////////////////

