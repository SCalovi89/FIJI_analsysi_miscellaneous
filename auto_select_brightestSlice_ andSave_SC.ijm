//Stefano Calovi, 15-01-24
//this macro allows you to select the brightest slice from a stack and save it in a seperate folder
macro "Search for brightest slice" {
    //Asks for your in- and output
    input = getDirectory("Choose Source Directory ");
    output = getDirectory("Choose Output Directory ");
    list = getFileList(input);


    //Asks you wether you want to approve the selection of each slice
    Dialog.create("Choice");
    Dialog.addCheckbox("Check this box, if you want to custumize each selection.", false);
    Dialog.show();
    UserInput = Dialog.getCheckbox();


    //Loop over images starts here
    for (i=0; i < list.length; i++) {  
        open(input+list[i]);
        imageTitle=getTitle();
        NewTitle = File.nameWithoutExtension + "_oneSliceOnly";

        //Measures the Mean Intensity of each slice and identifies the position of it
        run("Measure Stack...");
        M1 = Table.getColumn("Mean");
        //Array.print(M1);
        Max=Array.findMaxima(M1, 1);
        //Array.print(Max);

        AA=Max[0];
        AA=parseInt(AA);
        AA=AA+1;


        setSlice(AA);


        //If you specified that in the beginning here you will be asked to identify the best slice and confirm your descision
        if (UserInput == true) {
            run("Enhance Contrast", "saturated=0.35");
            waitForUser("Please make sure, that this is the slice you want, or select a different one!");
            AA=getSliceNumber();
        }

        s1="slices="+ AA + " delete";

        //Here the single image is extraced, renamed and saved
        run("Make Substack...", s1);
        //run("Duplicate...", "title=FinalImage duplicate range=AA-AA");
        
        saveAs("Tiff", output+NewTitle); 
        run("Close All");
        run("Clear Results");
    }

    showStatus("This Folder was completly analysed!");
}