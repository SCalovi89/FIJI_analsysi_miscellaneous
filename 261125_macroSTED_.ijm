//start with deconvolved image opened - for 2d sted (IMO)
//FOR MAX OF 25 CLUSTERS!!
title = getString("Give a title to this image", "CNO or VEH");
run("Subtract Background...", "rolling=50");
run("16-bit");
run("Bleach Correction", "correction=[Simple Ratio] background=0");
rename("corrected_all");
//node isolation
run("Enhance Contrast", "saturated=0.35");
Stack.setChannel(2);
run("Enhance Contrast", "saturated=0.35");
Property.set("CompositeProjection", "Sum");
Stack.setDisplayMode("composite");
tot_sl = nSlices;
tot_stack = tot_sl/2;
run("Duplicate...", "title=scanner duplicate slices=4-"+ tot_stack-3);
run("RGB Color", "slices");

//for a max of 10 nodes per pics;
for (i = 1; i < 10; i++) {
	selectImage("scanner");

	// ask the user if there are still nodes
	cont = getBoolean("Are there still nodes to analyze?");
	if (!cont) {
	    // clean up: close everything except the results table
	    ids = getList("image.titles");
	    for (j=0; j<ids.length; j++) {
	        if (ids[j] != "macro2_results") {
	            selectWindow(ids[j]);
	            close();
	        }
	    }
	    exit(); // exit the macro entirely
	}
	
	// if user clicked Yes, continue as before
	run("Orthogonal Views");
	waitForUser("find optimal z plane");
	run("Orthogonal Views");
	//selection of homovlumetric (7stacks) nodes
	setTool("rotrect");
	makeRotatedRectangle(514, 158, 552, 245, 70);
	waitForUser("select a node");
	punctual_z = getSliceNumber();
	last_z = punctual_z+6;
	roiManager("reset");
	roiManager("Add");
	selectImage("corrected_all");
	roiManager("Select", 0);
	run("Duplicate...", "duplicate slices=" + punctual_z + "-" + last_z);
	roiManager("reset");

	//clean to not repeat counting
	selectImage("scanner");
	setBackgroundColor(0, 0, 0);
	run("Clear", "slice");
	
	//analysis nev clusters via automated thresholding
	selectImage("corrected_all-1");
	rename("corrected");
	
	//manual length nodes
	run("Z Project...", "projection=[Max Intensity]");
	Property.set("CompositeProjection", "null");
	Stack.setDisplayMode("color");
	Stack.setChannel(2);
	setMinAndMax(50, 2000);
	Property.set("CompositeProjection", "Sum");
	Stack.setDisplayMode("composite");
	run("In [+]");
	run("In [+]");
	run("In [+]");
	run("In [+]");
	run("In [+]");
	setTool("line");
	waitForUser("MANUAL 2D LENGTH: do the line");
	run("Measure");
	length_man = getResult("Length");
	run("Clear Results");

	//final cleaning - border signals out
	setTool("polygon");
	waitForUser("design the exact node on the projection");
	roiManager("Add");
	selectImage("corrected");
	run("Duplicate...", "title=Nav_clust duplicate channels=1");
	roiManager("Select", 0);
	run("Clear Outside", "stack");
	roiManager("reset");
	selectImage("MAX_corrected");
	close;
	
	//fixed threshold - 
	selectImage("Nav_clust");
	setThreshold(1500, 65535, "raw");
	run("Convert to Mask", "method=Moments background=Dark black create");
	rename("fixed_1500");
	//analysis fixed:
	run("3D Objects Counter on GPU (CLIJx, Experimental)", "cl_device=[NVIDIA GeForce RTX 3060] threshold=128 slice=3 min.=0 max.=74480 objects");
	selectImage("fixed_1500");
	close;
	selectImage("Objects map of fixed_1500 (experimental, clij)");
	rename("fixed_1500");

	//3d volume calculations
	run("3D Manager");
	Ext.Manager3D_AddImage;
	Ext.Manager3D_Fill3DViewer(255, 255, 255);
	call("ij3d.ImageJ3DViewer.setCoordinateSystem", "false");
	call("ij3d.ImageJ3DViewer.lock");
	waitForUser("Last check: is node ok or EXIT?");
	selectImage("Nav_clust");
	///////////with chat making an output
	// === new robust 3D-manager -> table block ===
	Ext.Manager3D_SelectAll;
	
	// get number of objects in the Manager
	Ext.Manager3D_Count(nRes); // nRes will contain number of objects
	maxK = 25; // max number of object-columns (adjust if you expect >50 objects)

	// prepare arrays
	volumes = newArray(nRes);
	surfaces = newArray(nRes);
	means = newArray(nRes);

	// ask 3D Manager for each object's measures (no need to parse QuantifTable)
	for (r = 0; r < nRes; r++) {
	    // geometric measures
	    Ext.Manager3D_Measure3D(r, "Vol", tmpVol);    // volume
	    volumes[r] = tmpVol;
	    Ext.Manager3D_Measure3D(r, "Surf", tmpSurf);  // surface
	    surfaces[r] = tmpSurf;
	    // intensity quantification (3D)
	    Ext.Manager3D_Quantif3D(r, "Mean", tmpMean);  // mean intensity
	    means[r] = tmpMean;
	}

	// Create table and headers (only once)
	if (isOpen("macro2_results") == 0) {
	    Table.create("macro2_results");
	    // header row index 0
	    Table.set("Title", 0, "Title");
	    Table.set("Length", 0, "Length");
	    Table.set("N_Objects", 0, "N_Objects");
	    for (k = 1; k <= maxK; k++) Table.set("Vol" + k, 0, "Vol" + k);
	    for (k = 1; k <= maxK; k++) Table.set("Surf" + k, 0, "Surf" + k);
	    for (k = 1; k <= maxK; k++) Table.set("Mean" + k, 0, "Mean" + k);
	}

	// append one row for this node
	row = Table.size("macro2_results"); // next free row index
	Table.set("Title", row, title + "_" + i);
	Table.set("Length", row, length_man);
	Table.set("N_Objects", row, nRes);

	// write Vol, Surf, Mean into their columns (1-based column suffix)
	for (r = 0; r < nRes && r < maxK; r++) Table.set("Vol"  + (r+1), row, volumes[r]);
	for (r = 0; r < nRes && r < maxK; r++) Table.set("Surf" + (r+1), row, surfaces[r]);
	for (r = 0; r < nRes && r < maxK; r++) Table.set("Mean" + (r+1), row, means[r]);

	Table.update("macro2_results"); // refresh display
	// === end replacement block ===

	/////

	////////final cleaning!!!
	Ext.Manager3D_SelectAll;
	Ext.Manager3D_Delete;

	print("\\Clear");

	waitForUser("manually close the 3d viewer!!");

///////////////////////////////////////////////////
	
	//moments threshold - auto calc 
	selectImage("Nav_clust");
	run("Convert to Mask", "method=Moments background=Dark calculate black create");
	rename("moments");
	//analysis MOMENTS-CALC:
	run("3D Objects Counter on GPU (CLIJx, Experimental)", "cl_device=[NVIDIA GeForce RTX 3060] threshold=128 slice=3 min.=0 max.=74480 objects");
	selectImage("moments");
	close;
	selectImage("Objects map of moments (experimental, clij)");
	rename("moments");
	
	//3d volume calculations
	run("3D Manager");
	Ext.Manager3D_AddImage;
	Ext.Manager3D_Fill3DViewer(255, 255, 255);
	call("ij3d.ImageJ3DViewer.setCoordinateSystem", "false");
	call("ij3d.ImageJ3DViewer.lock");
	waitForUser("Last check: is node ok or EXIT?");
	selectImage("Nav_clust");
	///////////with chat making an output
	// === new robust 3D-manager -> table block ===
	Ext.Manager3D_SelectAll;
	
	// get number of objects in the Manager
	Ext.Manager3D_Count(nRes); // nRes will contain number of objects
	maxK = 25; // max number of object-columns (adjust if you expect >50 objects)

	// prepare arrays
	volumes = newArray(nRes);
	surfaces = newArray(nRes);
	means = newArray(nRes);

	// ask 3D Manager for each object's measures (no need to parse QuantifTable)
	for (r = 0; r < nRes; r++) {
	    // geometric measures
	    Ext.Manager3D_Measure3D(r, "Vol", tmpVol);    // volume
	    volumes[r] = tmpVol;
	    Ext.Manager3D_Measure3D(r, "Surf", tmpSurf);  // surface
	    surfaces[r] = tmpSurf;
	    // intensity quantification (3D)
	    Ext.Manager3D_Quantif3D(r, "Mean", tmpMean);  // mean intensity
	    means[r] = tmpMean;
	}

	// Create table and headers (only once)
	if (isOpen("macro2_results") == 0) {
	    Table.create("macro2_results");
	    // header row index 0
	    Table.set("Title", 0, "Title");
	    Table.set("Length", 0, "Length");
	    Table.set("N_Objects", 0, "N_Objects");
	    for (k = 1; k <= maxK; k++) Table.set("Vol" + k, 0, "Vol" + k);
	    for (k = 1; k <= maxK; k++) Table.set("Surf" + k, 0, "Surf" + k);
	    for (k = 1; k <= maxK; k++) Table.set("Mean" + k, 0, "Mean" + k);
	}

	// append one row for this node
	row = Table.size("macro2_results"); // next free row index
	Table.set("Title", row, title + "_" + i);
	Table.set("Length", row, length_man);
	Table.set("N_Objects", row, nRes);

	// write Vol, Surf, Mean into their columns (1-based column suffix)
	for (r = 0; r < nRes && r < maxK; r++) Table.set("Vol"  + (r+1), row, volumes[r]);
	for (r = 0; r < nRes && r < maxK; r++) Table.set("Surf" + (r+1), row, surfaces[r]);
	for (r = 0; r < nRes && r < maxK; r++) Table.set("Mean" + (r+1), row, means[r]);

	Table.update("macro2_results"); // refresh display
	// === end replacement block ===

	/////

	////////final cleaning!!!
	Ext.Manager3D_SelectAll;
	Ext.Manager3D_Delete;

	print("\\Clear");
	waitForUser("manually close the 3d viewer!!");
	//to save at the end in: D:\Stefano\sted bordeaux\imo_nov25\ordered_decon_pics
	selectImage("corrected");
	saveAs("Tiff", "D:/Stefano/sted bordeaux/imo_nov25/ordered_decon_pics/isolated_nodes_results/"+title+"_"+i+"_3d.tif");

	close;
	selectImage("fixed_1500");
	close;
	selectImage("moments");
	close;
	selectImage("Nav_clust");
	close;

}
run("Close All");
print("finished the picture!! go on with the next one :)");
	
