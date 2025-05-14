//Atefano Calovi, 140525, auto open czi files 
//Prompt for folder
inputDir = getDirectory("Choose a folder with CZI files");

//Get all .czi files in the folder - compile array
list = getFileList(inputDir);

//Loop through each file
for (i = 0; i < list.length; i++) {
    filename = list[i];
    if (endsWith(filename, ".czi")) {
        fullPath = inputDir + filename;

        //Use Bio-Formats to open the CZI file
        run("Bio-Formats Importer", 
            "open=[" + fullPath + "] " + 
            "autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");

        //Process image here

        //Close images after processing
        run("Close All");
    }
}
