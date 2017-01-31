#!/bin/bash

# NPNL Lab
# Semi-automated Robust Quantification of Lesions (SRQL)Toolbox
# brainhack 2016
# KLI kaoriito(at)usc.edu 20170131

clear;
cd ~;


##################################### FUNCTIONS ##########################################
# function 1 - brain extraction

function brain_extraction {

	bet $ANATOMICAL $SUBJECTOPDIR/${Subject}_Brain -R -f 0.5 -g 0
	
}

##########################################################################################
# function 2 - perform registration

function run_reg {
	
	flirt -in $BET_Brain -ref $STANDARD -out $SUBJECTOPDIR/${Subject}_Reg_brain -omat $SUBJECTOPDIR/${Subject}_Reg.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  -interp trilinear
	
}


##########################################################################################
# function 3 - calculate white matter adjusted lesion volume

function lesion_vol {
	
	#binarize lesion and WM masks#
	fslmaths $LESION -bin $SUBJECTOPDIR/Intermediate_Files/${Subject}_LESION_MASK${counter}_bin;
	fslmaths $WM_MASK -bin $SUBJECTOPDIR/Intermediate_Files/${Subject}_WM_Mask_bin;
	
	MEANVAL=`fslstats $ANATOMICAL -k $SUBJECTOPDIR/Intermediate_Files/${Subject}_WM_MASK_bin -M`; #takes the mean intensity value in the white matter mask from subject's anatomical
	STDEV=`fslstats $ANATOMICAL -k $SUBJECTOPDIR/Intermediate_Files/${Subject}_WM_MASK_bin -S`;
	
	echo $MEANVAL > $SUBJECTOPDIR/Intermediate_Files/mean.txt;
	echo $STDEV > $SUBJECTOPDIR/Intermediate_Files/stdev.txt;
	
	DIFFERENCE=$(echo "$MEANVAL - $STDEV" | bc -l); #take the mean minus 1 standard deviation; use as threshold
	
	#apply T1 intensity to the stroke mask
	if `fslmaths $ANATOMICAL -mul $SUBJECTOPDIR/Intermediate_Files/${Subject}_LESION_MASK${counter}_bin $SUBJECTOPDIR/Intermediate_Files/${Subject}_LESION${counter}_NORMRANGE` ; then

		#get rid of all voxels with intensity higher than the threshold
		fslmaths $SUBJECTOPDIR/Intermediate_Files/${Subject}_LESION${counter}_NORMRANGE -uthr $DIFFERENCE $SUBJECTOPDIR/Intermediate_Files/${Subject}_WMAdjusted_Lesion${counter};
	
		#binarize WM adjusted lesion mask#
		fslmaths $SUBJECTOPDIR/Intermediate_Files/${Subject}_WMAdjusted_Lesion${counter} -bin $SUBJECTOPDIR/${Subject}_WMAdjusted_Lesion${counter};
	
		local LesionVOL=`fslstats $SUBJECTOPDIR/${Subject}_WMAdjusted_Lesion${counter} -V | awk '{print $2;}'`;
	
		echo $LesionVOL >> $SUBJECTOPDIR/${Subject}_LesionVOL.txt;
	
	else
		LesionVOL='X';
		echo $"Check orientation of lesion mask ${counter} for Subject ${Subject}" > /dev/tty 
		
	fi
	
	echo "$LesionVOL";

}


##########################################################################################
#function 4: call lesion volume function for each lesion, then outputs single array per subject

function create_subj_array () {

	WM_MASK=`ls ${Subject}*${WM_ID}.nii*`;
	
	#get lesion files
	LESIONFILES=`ls -d ${Subject}*${LESION_MASK}*.nii*`;
	
	declare -a SubjInfoArray;
	
	TotalNativeBrainVol=`fslstats $BET_Brain -V | awk '{print $2;}'`;
	
	SubjInfoArray=($Group $Subject $TotalNativeBrainVol);
	
	if [ "$lesion2standard" == 1 ]; then
		
		TotalStandardBrainVol=`fslstats $RegBrain -V | awk '{print $2;}'`;
		SubjInfoArray+=(${TotalStandardBrainVol});
	fi
	
	counter=1;
	
	for LESION in $LESIONFILES; do
			
			# calculate subject's white matter adjusted lesion volume#
			SubjLesionVol=$( lesion_vol )
			
			if [ "$SubjLesionVol" != 'X' ]; then
				#calculate percentage of lesion/total brain vol
				PercentVol=$(awk "BEGIN {printf \"%.9f\",${SubjLesionVol}/${TotalNativeBrainVol}} END{}");
			
			else
				PercentVol='X';
			
			fi
			
			#determine side of lesion
				#this gets the center of gravity of the lesion using the mni coord and then extracts the first char of the X coordinate
			LesionCOG=`fslstats ${LESION} -c | awk '{print substr($0,0,1)}'`; 
			if [ $LesionCOG == '-' ];
				then
				LesionSide='L';
			else
				LesionSide='R';
			fi
			
			#concatenate onto array with all lesion volumes and percentage:
			SubjInfoArray+=(${LesionSide});
			SubjInfoArray+=(${SubjLesionVol});
			SubjInfoArray+=(${PercentVol});
			
			
			# optional: register lesion to standard space #

			if [ "$lesion2standard" == 1 ] ; then
			
				if [ "$SubjLesionVol" != 'X' ] ; then
			
					flirt -in $SUBJECTOPDIR/${Subject}_WMAdjusted_Lesion${counter} -applyxfm -init $RegFile -out $SUBJECTOPDIR/${Subject}_WMAdjusted_Lesion${counter}_SS -paddingsize 0.0 -interp trilinear -ref $RegBrain
				
					SSLesionVol=`fslstats $SUBJECTOPDIR/${Subject}_WMAdjusted_Lesion${counter}_SS -V | awk '{print $2;}'`; 
				
					SSPercentVol=$(awk -v LesionVol="$SSLesionVol" -v BrainVol="$TotalStandardBrainVol" 'BEGIN {printf "%.9f\n", LesionVol / BrainVol }');
	
				else
					
					SSLesionVol='X';
					SSPercentVol='X';
				
				fi
				
				SubjInfoArray+=(${SSLesionVol});
				SubjInfoArray+=(${SSPercentVol});
			fi
						
			counter=$((counter+1)) 
			
	done
	
	#TotalLesionVol=$(awk '{ sum += $1 } END { print sum }' $SUBJECTOPDIR/${Subject}_LesionVOL.txt);
	 
	printf '%s,' ${SubjInfoArray[@]} >> $WORKINGDIR/lesion_data.csv;
	printf '\n' >> $WORKINGDIR/lesion_data.csv;
}


##########################################################################################
#function 5: calls all other functions (depending on user input) for each subject.

function subject_func () {
	
	ANATOMICAL=`ls ${Subject}*${ANATOMICAL_ID}*.nii*`;
	
# perform brain extraction #

	if [ $RunBET == 1 ]; 
		then
		brain_extraction;
		BET_Brain=$SUBJECTOPDIR/${Subject}_Brain.nii.gz;
	else

		BET_Brain=`ls ${Subject}*${BET_ID}.nii*`;
	fi

# perform registration #	

	if [ $RunNormalization == 1 ]; then
		#call registration function; assign to variable
		run_reg
		RegFile=$SUBJECTOPDIR/${Subject}_Reg.mat;
		RegBrain=$SUBJECTOPDIR/${Subject}_Reg_brain.nii*;
	else
		#assign registration file to variable (MUST be on skull stripped brain)					
		RegFile=`ls ${Subject}*${REG_BRAIN}*.mat`;
		RegBrain=`ls ${Subject}*${REG_BRAIN}*.nii*`;
	fi


# create subject array and place into csv file #	

	create_subj_array 
}



################################ END OF FUNCTIONS ########################################

####################################[ SCRIPT BEGINS ]#####################################

############################## READ INPUTS & SET OPTIONS #################################

#Identify location of input directory. 
echo "Please specify the location of your input directory. (e.g., /Users/Lily/ProjectX/Input_Data)";
read INPUTDIR;

#Identify location of output directory. 
echo "Please specify the location you would like your outputs to be stored. (e.g., /Users/Lily/ProjectX/Outputs)";
read WORKINGDIR;

echo "Are you running more than one group? ('y'/'n')";
read NUMGROUPS;

echo "Please specify anatomical image identifier/wildcard. (e.g., T1 if Subj01_T1 or F013_T1 is your anatomical image.)"
read ANATOMICAL_ID;

echo "Please specify your lesion mask identifier/wildcard (e.g., lesion_mask if subj01_lesion_mask or F013_lesion_mask is your identifier)";
read LESION_MASK;

echo "Please specify your white matter mask identifier/wildcard (e.g., WM if subj01_WM or F013_WM is your identifier)";
read WM_ID;



##########################################################################################

echo "Output lesion data in standard space? ('y'/'n')"
# **NOTE** Must respond 'y' in order to create a lesion heat map (future).
read LESION2STANDARD;

if [ $LESION2STANDARD == 'y' ] || [ $LESION2STANDARD == 'yes' ]; then
	lesion2standard=1;
else
	lesion2standard=0;
fi

echo "Have you performed skull stripping on your anatomical images? ('y'/'n')"
read BETOPTION;

	if [ $BETOPTION == 'y' ] || [ $BETOPTION == 'yes' ]; then 
		RunBET=0; 
		echo "Please specify skull stripped brain identifier (e.g., brain)";
		read BET_ID;
		
		if [ "$lesion2standard" == 1 ]; then
			
			echo "Have you normalized your anatomical data to standard space? ('y'/'n')"
			read NORMALIZEOPTION;
	
			if [ $NORMALIZEOPTION == 'y' ] || [ $NORMALIZEOPTION == 'yes' ]; then 
		
				RunNormalization=0; #normalization will not run if it's already been run
				echo "Please specify the identifier for the normalized brain (e.g., 'brain_reg')";
				read REG_BRAIN;
		
			elif [ $NORMALIZEOPTION == 'n' ] || [ $NORMALIZEOPTION == 'no' ]; then
				RunNormalization=1;	
				echo "run registration"	
		
			else
				echo "Please respond with y or n ."

			fi	
		else
			RunNormalization=0;
		fi
		
	elif [ $BETOPTION == 'n' ] || [ $BETOPTION == 'no' ]; then
		RunBET=1;	
		echo "run brain extraction"
		
		if [ "$lesion2standard" == 1 ]; then
			echo "run registration"
			RunNormalization=1;
		else
			RunNormalization=0;
		fi
		
	else
		echo "Please respond with y or n ."
	fi

if [ $RunNormalization == 1 ]; then
	echo "Please specify the full path to a standard/reference brain (e.g., /Users/Lily/ProjectX/Standard/MNI_152T1_brain.nii)"
	read STANDARD;
fi

############################## CREATE OUTPUT DIRECTORIES #################################


cd $INPUTDIR;

if [ $NUMGROUPS == 'n' ] || [ $NUMGROUPS == 'no' ]; then

	SUBJECTS=`ls -d *`;
	
	cd $WORKINGDIR;
	
	for Subject in $SUBJECTS; do
		mkdir $Subject;
		cd $Subject;
		mkdir Intermediate_Files;
		cd $WORKINGDIR/$Group;
	done

else

	ALLGROUPS=`ls -d *`; 
	
	for Group in $ALLGROUPS; do
		cd $INPUTDIR/$Group;
		
		SUBJECTS=`ls -d *`;
		
		cd $WORKINGDIR;
		
		mkdir $Group;
		
		cd $WORKINGDIR/$Group;
		
		for Subject in $SUBJECTS; do
			mkdir $Subject;
			cd $Subject;
			mkdir Intermediate_Files;
			cd $WORKINGDIR/$Group;
		done
		
	done

fi



##########################################################################################

####################################[ MAIN SCRIPT ]#######################################

cd ~;
cd $INPUTDIR; 
pwd;

maxlesions=1;

if [ $NUMGROUPS == 'n' ] || [ $NUMGROUPS == 'no' ]; then
	Group='Group01';
	SUBJECTS=`ls -d *`;
	
	for Subject in $SUBJECTS; do
		cd $Subject;
		
		SUBJECTOPDIR=$WORKINGDIR/$Subject;
		
		##
		
		subject_func; 
			
		NumLesionFiles=`ls -d ${Subject}*${LESION_MASK}*.nii* | wc -l`;
		
 		if (( $maxlesions < $NumLesionFiles )); then
 			maxlesions=$NumLesionFiles;
 				
			echo "updated num of max lesions: "$maxlesions;
 		fi
		
		##
		
		cd $INPUTDIR;
		
	done
	
else
	
	ALLGROUPS=`ls -d *`; 
		
	for Group in $ALLGROUPS; do
		echo $Group;
		
		cd $INPUTDIR/$Group;
		
		SUBJECTS=`ls -d *`;
		
		echo $SUBJECTS;
		
		for Subject in $SUBJECTS; do
			cd $Subject;
			SUBJECTOPDIR=$WORKINGDIR/$Group/$Subject;
			
			##
		
			subject_func;
			
			NumLesionFiles=`ls -d ${Subject}*${LESION_MASK}*.nii* | wc -l`;
		
 			if (( $maxlesions < $NumLesionFiles )); then
 				maxlesions=$NumLesionFiles;
 				
				echo "updated num of max lesions: "$maxlesions;
 			fi
		
			##
	
			cd $INPUTDIR/$Group;	
			
		done	
		
		cd $INPUTDIR;
		
	done

fi

################################# ADD HEADER TO DATAFILE #################################

	cd $WORKINGDIR;
	declare -a HeaderArray;
	HeaderArray=(Group Subject Total_Native_Volume);
	
	if  [ "$lesion2standard" == 1 ]; then
		HeaderArray+=(Total_Standard_Volume);
	fi
	
	for i in $(seq 1 $maxlesions); do 
		HeaderArray+=(Lesion${i}_Hemisphere);
		HeaderArray+=(Lesion${i}_Native_Volume); 
		HeaderArray+=(Lesion${i}_Native_Percentage);
		
		if  [ "$lesion2standard" == 1 ]; then
			HeaderArray+=(Lesion${i}_Standard_Volume); 
			HeaderArray+=(Lesion${i}_Standard_Percentage);
		fi
	
	done
	
	StringArray=$(IFS=, ; echo "${HeaderArray[*]}")
	
	awk -v env_var="${StringArray}" 'BEGIN{print env_var "\n"}{print}' lesion_data.csv > lesion_database.csv;

	rm $WORKINGDIR/lesion_data.csv;

####################################[ END OF SCRIPT ]#####################################