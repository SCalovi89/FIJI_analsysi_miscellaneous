//stefano calovi _ merging of 2 "poker deck" stacks_6-11-24
// Get the title of the opened stack and the number of slices
originalStack = getTitle();
width = getWidth();
height = getHeight();
n_sl = nSlices;

// Calculate slices for the even and odd stacks
evenSlices = floor(nSlices / 2);
oddSlices = nSlices - evenSlices;

print(evenSlices + "_" + oddSlices);
// Create new stacks for even and odd slices
run("New...", "name=EvenStack width=" + width + " height=" + height + " slices=" + evenSlices + " bit-depth=" + bitDepth);
run("New...", "name=OddStack width=" + width + " height=" + height + " slices=" + oddSlices + " bit-depth=" + bitDepth);

evenIndex = 1;
oddIndex = 1;

// Loop through the slices of the original stack
for (i = 1; i <= n_sl; i++) {
    selectWindow(originalStack);
    setSlice(i);
    run("Copy");
    
    if (i % 2 == 0) {
        selectWindow("EvenStack");
        setSlice(evenIndex);
        run("Paste");
        evenIndex++;
    } else {
        selectWindow("OddStack");
        setSlice(oddIndex);
        run("Paste");
        oddIndex++;
    }
}

// Merge stacks as 2 channels
run("Merge Channels...", "c1=OddStack c2=EvenStack create keep");

// Optionally, close the intermediate stacks if not needed
selectWindow("EvenStack");
close();
selectWindow("OddStack");
close();
