//STEFANO CALOVI, IMAGE SUPERCALCULATOR, 17 10 25
//start with images u want to calculate already opened
all_images = getList("image.titles");

// Create dialog with 2 scrolling menus
Dialog.create("SUPERCALCULATOR");
Dialog.addMessage("Welcome to the SUPERCALCULATOR!\n\nSelect 2 images to calculate:");
Dialog.addChoice("Select polarized channel 1:", all_images, all_images[0]);
Dialog.addChoice("Select polarized channel 2:", all_images, all_images[0]);
Dialog.addMessage("...to change the math, go to the\n\nmacro section:here is the math!!");
Dialog.show();

// Grab the selected names
title1 = Dialog.getChoice();
title2 = Dialog.getChoice();

selectImage(title1);
rename("test1");

selectImage(title2);
rename("test2");

run("Merge Channels...", "c1=test1 c2=test2 create keep ignore");


selectImage("Composite");
rename("try1");

run("Split Channels");

run("Duplicate...", "title=Result  duplicate channels=1");
run("32-bit");

// Get image dimensions
width = getWidth();
height = getHeight();
n_Slices = nSlices();

total = width * height;

progressMarks = newArray(10,20,30,40,50,60,70,80,90); 

// Loop over all pixels
setBatchMode(true);
// Loop over slices
for (z=1; z<=n_Slices; z++) {
    setSlice(z);                     // move result slice
    selectWindow("C1-try1"); setSlice(z); // img1 current slice
    selectWindow("C2-try1"); setSlice(z); // img2 current slice
	counter = 0;
	nextMark = 0; // index in progressMarks
	for (y=0; y<height; y++) {
	    for (x=0; x<width; x++) {
		    selectImage("C1-try1");
		    v1 = getPixel(x, y);
		    selectImage("C2-try1");
		    v2 = getPixel(x, y);
//////////////////////////////////////here is the math!!
		    if (v2!=0) {
		    	//a = (v1 / v2) * 100; ver.1
		    	a = exp(v1 / v2);
		    } else {
		    	a = 0; // avoid division by 0
		    }
//////////////////////////////////////here finishes the math
	        selectImage("Result");
	        setPixel(x, y, a);
	        //counter = counter + 1;
	        counter++;
	        perc = (counter*100)/total;
	        if (nextMark < lengthOf(progressMarks)) {
	            if (perc >= progressMarks[nextMark]) {
	                print("calculating slice" + z + ", " + progressMarks[nextMark] + "% done");
	                nextMark++;
	            }
	        }
        
	    }
	}
}
selectImage("C1-try1");
close;
selectImage("C2-try1");
close;
// Show result
selectImage("Result");
run("Brightness/Contrast...");
run("Enhance Contrast", "saturated=0.35");


print("Calculation finished");