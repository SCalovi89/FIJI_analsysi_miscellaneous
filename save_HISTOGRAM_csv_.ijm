///////author: Stefano Calovi, 030424
////////run and save histogram - change the parameter from result table and insert your destination folder!
selectWindow("Log");
print("\\Clear");
run("Distribution...", "parameter=******* or=10 and=0-255");
//selectImage("BG_corr Distribution");
selectWindow("BG_corr Distribution");
Plot.getValues(bins, counts);
Array.print (bins);
Array.print (counts);
selectWindow("Log");
//////////////////here the saving path if wanted
saveAs("Text", "***********_dist.csv");
////////////////////
print("\\Clear");
////////