#!/bin/bash

# 20170802 KLI kaoriito@usc.edu
# Follow-up to QC1_makeImages.sh
# Creates html file called QC_Lesions.html with all subjects and their primary lesions
# Takes subject directories that contain both the T1 and primary lesion screen shots, and outputs into a single QC html page.

function makeHTML {

cd $ROOTDIR;
subjects=`ls -d ${subjID}*`;

#set up html and css headers
echo "<html>" >  QC_Lesions.html
echo "<head>" >> QC_Lesions.html
echo "<style type=\"text/css\">" >> QC_Lesions.html
echo "*" >> QC_Lesions.html
echo "{" >> QC_Lesions.html
echo "margin: 0px;" >> QC_Lesions.html
echo "padding: 0px;" >> QC_Lesions.html
echo "}" >> QC_Lesions.html
echo "html, body" >> QC_Lesions.html
echo "{" >> QC_Lesions.html
echo "height: 100%;" >> QC_Lesions.html
echo "}" >> QC_Lesions.html

#these containers specify the size of the images
echo ".container { " >> QC_Lesions.html
echo "width: 500px;" >> QC_Lesions.html
echo "height: 240px;" >> QC_Lesions.html
echo "overflow: hidden;" >> QC_Lesions.html
echo "}" >> QC_Lesions.html

echo ".container img { " >> QC_Lesions.html
echo " width: 100%;" >> QC_Lesions.html
echo " margin-top: -200px;" >> QC_Lesions.html
echo "}" >> QC_Lesions.html
echo "</style>" >> QC_Lesions.html
echo "</head>" >> QC_Lesions.html
echo "<body>" >> QC_Lesions.html


#for each subject, make table containing image outputs
for subj in $subjects; do

	echo "<table cellspacing=\"1\" style=\"width:100%;background-color:#000;\">" >> QC_Lesions.html
	echo "<tr>"	>> QC_Lesions.html
	echo "<td> <FONT COLOR=WHITE FACE=\"Geneva, Arial\" SIZE=5> $subj </FONT> </td>" >> QC_Lesions.html
	echo "</tr>" >> QC_Lesions.html
	echo "<tr>" >> QC_Lesions.html
	echo "<td><FONT COLOR=WHITE FACE=\"Geneva, Arial\" SIZE=3> T1 </FONT><div class=\"container\"><a href=\"file:Visualize/"$subj"_t1.png\"><img src=\"Visualize/"$subj"_t1.png\" height=\"700\" ></a></div></td>" >> QC_Lesions.html
	echo "<td><FONT COLOR=WHITE FACE=\"Geneva, Arial\" SIZE=3> Lesion Segmentation </FONT><div class=\"container\"><a href=\"file:Visualize/"$subj"_primaryLes.png\"><img src=\"Visualize/"$subj"_primaryLes.png\" height=\"700\" ></a></div></td>" >> QC_Lesions.html
	echo "</tr>" >> QC_Lesions.html
	echo "</table>" >> QC_Lesions.html

done;

echo "</body>" >> QC_Lesions.html

echo "</html>" >> QC_Lesions.html

}
