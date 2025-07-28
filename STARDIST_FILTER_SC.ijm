////////////LOOP THROUGH ROI MANAGER TO EXCLUDE FALSE POSITIVE
//author: Stefano Calovi, jul2025

//this macro is to be inserted after a stardist counting (for cell/nuclear counting), like the example:
/////stardist count:
	roiManager("reset");
	selectImage("cFos_tostar");
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'cFos_tostar', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.1', 'percentileTop':'99.9', 'probThresh':'0.479071', 'nmsThresh':'0.3', 'outputType':'Both', 'nTiles':'2', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	wait(5000);

	selectImage("Label Image");
	close();

//to exclude false positive, here in practice all rois which are: too big/small (number of pixel per macro, Note: pixel not area!!), not circular (circularity here 0,5), cells with a weaker signla respect to the background (NOTE: previously calculated!), and all rois with black (0 value) pixels (typically artifacts or bubbles!!!)
//change all the poarameters according to your pictures!

////////////LOOP THROUGH ROI MANAGER TO EXCLUDE FALSE POSITIVE

	// Set initial parameters (opixels
	minimum_size = 100;
	maximum_size = 800;
	min_circ = 0.5;
	cf_BG = 0; //insert the background value (suggestion: in 8-bit) of the cfos staining.
	run("Set Measurements...", "area mean shape display redirect=None decimal=3");

	// Initialize arrays to hold indices of ROIs to be deleted
	to_be_deleted = newArray();

	n_rois = roiManager("count");

	// Loop through each ROI
	for (j = 0; j < n_rois; j++) {
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
    
 	    // Check is over BG mean MGV value
	    min_mean = getResult("Mean");
	    if (min_mean <= cf_BG) {
	        to_be_deleted = Array.concat(to_be_deleted, j);
	        continue; // Skip further checks for this ROI if circularity condition is met
	    }
    	
    // Check for black pixels
	    getStatistics(area, mean, min, max, std, histogram);
	    if (min <= 1) {
	        to_be_deleted = Array.concat(to_be_deleted, j);
	    }
	    
		run("Clear Results");
	}

	// Delete all ROIs that failed any of the conditions
	roiManager("Select", to_be_deleted);
	roiManager("Delete");
	run("Clear Results");

	////////////////NOW WE eliminated all incorrect rois