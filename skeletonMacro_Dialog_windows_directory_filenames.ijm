//author: stefano calovi 070424, skeleton macro for auto opening of tiff files and respective macros
// Display a message with "ritorno a capo" and wait for the user to click "OK"
waitForUser("This is just a skeleton to build over a macro to associate images and roiset.zip\n\n and open them by navigation_Premi OK per continuare.");
// Prompt the user for the input directory
inputDir = getDirectory("Select the directory where images are");
inputRoiDir = getDirectory("Select the directory where are maps on brain are\n\nthe file has to end in _RoiSet.zip");

// Get the list of all files in the input directory
fileList = getFileList(inputDir);

// Concatenate the file names into a single string
fileNamesString = "";
for (i = 0; i < fileList.length; i++) {
    fileNamesString += fileList[i] + "\n";
}

// Display the file names in a dialog window

showMessage("Select from this File List", fileNamesString);

// User Prompt for the file name
fileName = getString("Enter the image name without extension .tif", "");
// Append the file extension to the file name
fileRoiNameWithExtension = fileName + "_RoiSet.zip";
fileNameWithExtension = fileName + ".tif";

// No human in the loop, open all the files filtering if names containes: here CZI extension (u can choose for tiff etc)
for (i = 0; i < list.length; i++) {
    filename = list[i];
    if (endsWith(filename, ".czi")) {
        fullPath = inputDir + filename;

//Use Bio-Formats to open the CZI or other microscopy file
        fullPath = inputDir + filename;
        run("Bio-Formats Importer", 
            "open=[" + fullPath + "] " + 
            "autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");

// Prompt the user for the output directory
outputDir = getDirectory("Select the results directory");

//print("Input Directory: " + inputDir);
//print("Output Directory: " + outputDir);
//print("File Name: " + fileNameWithExtension);
//print("Full Input Path: " + inputPath);
//print("Full Output Path: " + outputPath);

inputPath = inputDir + fileNameWithExtension;
inuputRoiPath = inputRoiDir + fileRoiNameWithExtension
outputPath = outputDir;

//open(inputPath);
open(inputRoiPath);
