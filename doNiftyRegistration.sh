#!/bin/bash

#
#$ -l rmem=16G
#$ -l h_rt=6:00:00 
#$ -pe smp 8

####
#### NB: create 'logs' dir if not using pcqsub
####

#$ -e logs
#$ -o logs

export PATH=/shared/polarissf2/slib/tools/niftyreg/19.05/bin:${PATH}

ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NSLOTS  # controls multi-threading
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

for infl_lvl in frc+bag tlc rv
do
    echo ${infl_lvl}

    fxd=../my_data/${infl_lvl}_ref.nii.gz
    mvg=${infl_lvl}_nifty/${infl_lvl}_case.nii.gz
    lbl=${infl_lvl}_nifty/${infl_lvl}_case_pmask.nii.gz


    tform_root=${infl_lvl}_nifty/niftyrefM_regTo_caseF_

    regA="reg_aladin -ref ${fxd} -flo ${mvg} \
                     -res ${infl_lvl}_nifty/niftyRefWarpedToCaseAffine.nii.gz \
                     -aff ${tform_root}Affine.txt"

    regF="reg_f3d -ref ${fxd} -flo ${mvg} \
                  -res ${infl_lvl}_nifty/niftyRefWarpedToCaseF3D.nii.gz \
                  -aff ${tform_root}Affine.txt \
                  -cpp ${tform_root}CPP.nii.gz \
                  -sx -3 -sy -3 -sz -1"

echo $regA >&2
echo "" >&2
echo $regF >&2
echo "" >&2

$regA
$regF

# compute the warped label map
# i.e., the label map of the reference image warped onto the case image
reg_resample -ref ${fxd} -flo ${lbl} \
             -res ${infl_lvl}_nifty/lbl_est_${infl_lvl}.nii.gz \
             -trans ${tform_root}CPP.nii.gz -inter 0

done
