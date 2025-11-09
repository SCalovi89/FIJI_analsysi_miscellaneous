//author Stefano Calovi, 091125
//function to extract lesion + perilesion Rois, human in the loop modification
//the function les_periles need the imput: name of a pic + microns of the radius of the perilesion
run("Duplicate...", "title=to_anal_ duplicate");
les_periles("to_anal_", 100);

function les_periles(image, radius)
{
selectImage(image);
//get calculation in order not to exceed the limit of 255 pixel anular roi
getPixelSize(unit, pixelWidth, pixelHeight);
pix_w = pixelWidth;
raw_n_pixels = radius / pix_w;
n_pixels = parseInt(raw_n_pixels);
max_band = 254;
max_radius = pix_w * 254;
//print(n_pixels);

roiManager("reset");

selectImage(image);
title_lp = getTitle();
run("Duplicate...", "title=anal_ duplicate");
if (nSlices>0)
{
	run("Z Project...", "projection=[Max Intensity]");
	selectImage("anal_");
	close();
	
	rename("anal_");
} else {
	selectImage("MAX_anal_");
	rename("anal_");
}
setTool("polygon");
waitForUser("DESIGN ROI FOR LESION");
roiManager("Add");
roiManager("Select", 0);
roiManager("Rename", "LESION");


if (n_pixels < 255) {
	roiManager("Select", 0);
	run("Make Band...", "band="+ radius);
	roiManager("Add");
	roiManager("Select", 1);
	roiManager("Rename", "PERILESION");
} else {
counter = n_pixels;

while (counter > max_band) {
	if (roiManager("count")>1){
	last_roi = roiManager("count")-1;
	roiManager("select", last_roi);
	run("Convex Hull");
} else {
	roiManager("select", 0);
}	
    run("Make Band...", "band=" + max_radius);
    roiManager("Add");
    counter = counter - max_band;
}
if (counter < max_band) {
	last_roi = roiManager("count")-1;
	roiManager("select", last_roi);
	run("Convex Hull");
	last_radius = pix_w * counter;
	run("Make Band...", "band=" + last_radius);
    roiManager("Add");
}
final_rois = roiManager("count");
peril = newArray();
for (i = 0; i < final_rois-1; i++) {
	peril[i] = i+1;
}
//Array.print(peril);
roiManager("select", peril);
roiManager("Combine");
roiManager("Add");
roiManager("select", peril);
roiManager("delete");
roiManager("select", 1);
roiManager("Rename", "PERILESION");
}
// final correction: Ask the user if correction is needed
roiManager("Show All");
correct_ = getBoolean("u need to correct the perilesion roi", "yes", "no");

if (correct_) {
    // Let the user draw or edit an ROI
    waitForUser("Draw or edit the ROI, then click OK to continue.");
    
    // Add the drawn ROI to the ROI Manager
    roiManager("Add");
	roiManager("Select", newArray(1,2));
	roiManager("AND");
	roiManager("Add");
	roiManager("Select", newArray(1,2));
	roiManager("delete");
	roiManager("select", 1);
	roiManager("Rename", "PERILESION");
} else {
    // No correction, just finish
    print("No correction needed. roiing finished.");
}

selectImage("anal_");
close();
selectImage(image);
roiManager("Show All");
}


