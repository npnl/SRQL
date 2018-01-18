#!/bin/bash

# 20170802 KLI kaoriito@usc.edu
# Uses fsleyes to render .png images of each subjects' T1 image (${subj}_t1w_stx.nii.gz) and an overlay of the primary lesion (${subj}_LesionSmooth_stx.nii.gz) over the T1
# fsleyes must be installed and the command must be in the user's bash profile (or, replace the fsleyes command below with path to the executable file
# 	e.g., /home/Applications/fsleyes render)
# This script expects each subject to have its own directory containing the T1 and primary lesion nii.gz files within them
# QC2_makeHTML.sh should be run following this script to create the html QC page.


clear;

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

source "$DIR"/QC1_makeImages.sh;
source "$DIR"/QC2_makeHTML.sh;


#Identify location of input directory.
echo "Specify the location of your directory. (e.g., /Users/Lily/ProjectX/Lesions)";
read ROOTDIR;

echo "Specify your subject identifier (e.g., subj for subj01). Each subject should have their own directory. ";
read subjID;

echo "Specify your anatomical image identifier/wildcard (e.g., T1 if Subj01_T1 or F013_T1 is your anatomical image)."
read anatomicalID;

echo "Specify lesion mask identifier."
read lesionMask;

makeImages;
makeHTML;
