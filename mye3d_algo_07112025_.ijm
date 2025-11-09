//290925-30 // author Stefano Calovi
//MBP_algorythm

/////////////////for trying - to cancel
//run("Close All");
//open("F:/STEFANO ALL/ayriscan_/010725_MBP_chrCNO/1b_M_C_RSC_ms_Image 2_Airyscan Processing.czi");
//rename("TRYING");

///////////////////////ALGORYTHM//////////
//variables that are coinstants in the macro: (//add 1 value to nr areas)
thresh_V = 600;
nr_areas = 7;
thresh_MBP = 1700;
min_pixel_3dfilter = 15;
//result_dir = getDirectory("Choose a folder where to save the results");
//F:\STEFANO ALL\ayriscan_\chr_cno_allsexes_MBP\graphic_res
result_dir = "F:/STEFANO ALL/ayriscan_/chr_cno_allsexes_MBP/graphic_res/";

//starting with open pic - STACKS
title = getTitle();
rename("orig");
run("Duplicate...", "title=process duplicate");

//1. BISCUIT - TOTAL SLICE VOLUME - FIRST THRESH 0-250
selectImage("process");
run("Duplicate...", "title=VOLUME duplicate");
setThreshold(0, thresh_V, "raw");
setOption("BlackBackground", true);
run("Convert to Mask", "background=Light black");
run("Gaussian Blur...", "sigma=10 stack");
setThreshold(65, 255, "raw");
setOption("BlackBackground", true);
run("Convert to Mask", "background=Light black");
run("Invert", "stack");
rename("final_vol");


//2. roiing
selectImage("process");
run("Subtract Background...", "rolling=50 stack");
run("Z Project...", "projection=[Max Intensity]");
rename("ROI_selection");
setMinAndMax(0, 3000);
run("Apply LUT");

//START DESIGNING ROIS
for (i = 1; i < nr_areas; i++) {
	roiManager("reset");
	selectImage("ROI_selection");
	setTool("polygon");
	waitForUser("make n" + i + " roi");
	//get area asap
	run("Set Measurements...", "area display redirect=None decimal=2");
	run("Measure");
	surf_roi = getResult("Area");
	run("Clear Results");
	
	roiManager("Add");
	run("Clear", "slice");
	area_name = getString("name the area measuring", "LAY1");
	
	//2. MBP 3D
	selectImage("process");
	roiManager("Select", 0);

	run("Duplicate...", "title=MBP_3d duplicate");
	setBackgroundColor(0, 0, 0);
	run("Clear Outside", "stack");
	
	setThreshold(0, thresh_MBP, "raw");
	waitForUser("check thresh for 3d mbp");
	run("Convert to Mask", "background=Dark black");
	
	//processing 3d issue part
	run("Invert", "stack");
	run("3D Objects Counter on GPU (CLIJx, Experimental)", "cl_device=[NVIDIA GeForce RTX 3060] threshold=128 slice=15 min.=" + min_pixel_3dfilter +" max.=32148240 objects");

	//

	wait(5000);
	selectImage("MBP_3d");
	close;
	selectImage("Objects map of MBP_3d (experimental, clij)");
	rename("MBP_3d");
	setThreshold(1, 255, "raw");
	run("Convert to Mask", "black");

	//3. MBP 2D AND 3D SKEL
	run("Duplicate...", "title=MBP_3d_SKEL duplicate");
	run("8-bit");
	setThreshold(1, 255, "raw");
	run("Convert to Mask", "background=Dark black");
	run("Z Project...", "projection=[Max Intensity]");
	rename("MBP_2D");
	
	//////////////////////
	
	selectImage("MBP_3d_SKEL");
	run("Skeletonize (2D/3D)");

	//save graphic result
	selectImage("final_vol");
	roiManager("Select", 0);
	run("Duplicate...", "title=small_vol duplicate");
	setBackgroundColor(0, 0, 0);
	run("Clear Outside", "stack");
	run("Merge Channels...", "c1=MBP_3d c2=MBP_3d_SKEL c3=small_vol create keep ignore");
	selectImage("Composite");
	saveAs(result_dir + title +"_"+ area_name +".tif");
	close;

	//Start final measurements:
	
	//TOT VOLUME MICRON
	run("Clear Results");
	selectImage("small_vol");
	run("3D Volume");
	if (nResults == 1) {
		tot_vol_area = getResult("Volume(unit)");		
	} else {
		vol_part = nResults;
		//print("n particle: " + vol_part);
		run("Summarize");
		vol_mean = getResult("Volume(unit)", vol_part);
		//print("mean vol unit: " + vol_mean);
		tot_vol_area = vol_part * vol_mean;
		//print("tot vol unit: " + tot_vol_area);
		//
	}
	
	//MBP VOLUME MICRON
	run("Clear Results");
	selectImage("MBP_3d");
	run("3D Volume");
	vol_part = nResults;
		//print("n particle: " + vol_part);
	run("Summarize");
	vol_mean = getResult("Volume(unit)", vol_part);
		//print("mean vol unit: " + vol_mean);
	tot_vol_MBP = vol_part * vol_mean;
		//print("MBP vol unit: " + tot_vol_MBP);
	run("Clear Results");
	//
	
	//3d skeleton
	selectImage("MBP_3d_SKEL");
	run("Summarize Skeleton");
	selectWindow("Skeleton Stats"); 
	totalLength = Table.get("Total length", 0); // row 0, column "Total length"
		//print("Total length = " + totalLength);
	close("Skeleton Stats");
	

	//print results === Create table and headers (only once) ===
	if (isOpen("Mye3d_results") == 0) {
	    Table.create("Mye3d_results");
	    // header row index 0
	    Table.set("Name", 0, "Name");
	    Table.set("Area", 0, "Area");
	    Table.set("Tot Vol (um3)", 0, "Tot Vol (um3)");
	    Table.set("MBP Vol (um3)", 0, "MBP Vol (um3)");
	    Table.set("Total length", 0, "Total length");
	}

	// === Append one row for this iteration ===
	row = Table.size("Mye3d_results"); // next free row index
	Table.set("Name", row, title);
	Table.set("Area", row, area_name);
	Table.set("Tot Vol (um3)", row, tot_vol_area);
	Table.set("MBP Vol (um3)", row, tot_vol_MBP);
	Table.set("Total length", row, totalLength);

	// Refresh display
	Table.update("Mye3d_results");

	//backup printing
	print("Name, area, tot vol (um3), MBP vol (um3), Total length");
	print(title +","+ area_name +","+ tot_vol_area +","+ tot_vol_MBP +","+ totalLength);
	
	//clean before relooping
	selectImage("small_vol");
	close;
	selectImage("MBP_3d");
	close;
	selectImage("MBP_3d_SKEL");
	close;

	/////////////////////////////////////////
	selectImage("MBP_2D");

	run("Set Measurements...", "area area_fraction limit display redirect=None decimal=2");
	run("Measure");
	nonRoi_area = getResult("Area");
	perc_2d_nonRoi = getResult("%Area");
	st_area2d = (nonRoi_area / 100) * perc_2d_nonRoi;
	print(st_area2d);
	run("Clear Results");
	selectImage("MBP_2D");
	close;

}
run("Close All");

