#!/bin/bash


function makeImages {
	cd "$ROOTDIR" || exit;
	mkdir Visualize;

	subjects=`ls -d ${subjID}*`;

	for subj in $subjects; do

		cd $subj;

		cog=`fslstats ${ROOTDIR}/${subj}/${subj}_${lesionMask}.nii* -C`;

		cog=$( printf "%.0f\n" $cog );

		ANATOMICAL=$(ls "${ROOTDIR}"/${subj}/*"${anatomicalID}".nii*);

		LESION=$(ls "${ROOTDIR}"/${subj}/*"${lesionMask}".nii*);


		fsleyes render -vl $cog --hideCursor -of ${ROOTDIR}/Visualize/${subj}_t1.png "$ANATOMICAL";

		fsleyes render -vl $cog --hideCursor -of ${ROOTDIR}/Visualize/${subj}_primaryLes.png "$ANATOMICAL" \
		  "$LESION" -cm blue -a 40;


	cd ../;

	done

}
