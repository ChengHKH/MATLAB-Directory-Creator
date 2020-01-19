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

export PATH=/shared/polarissf2/slib/tools/ANTs/2018-11/bin:${PATH}

ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NSLOTS  # controls multi-threading
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS



for infl_lvl in frc+bag tlc rv
do
    echo ${infl_lvl}
    
    fxd=../my_data/${infl_lvl}_image.mha
    mvg=${infl_lvl}/${infl_lvl}_image.mha

    tform_root=${infl_lvl}/refM_regTo_caseF_

    regCmd="antsRegistration --dimensionality 3 --verbose 1 \
                 --output [${tform_root},${infl_lvl}/refWarpedToCase.mha,${infl_lvl}/caseWarpedToRef.mha] \
                 --use-histogram-matching 1 \
                 --initial-moving-transform [${fxd},${mvg},1] \
                 --transform Rigid[0.1] \
                 --metric MI[${fxd},${mvg},1,32,Regular,0.25] \
                 --convergence 1000x500x250 \
                 --smoothing-sigmas 2x1x0 \
                 --shrink-factors 4x2x1 \
                 --transform Affine[0.1] \
                 --metric MI[${fxd},${mvg},1,32,Regular,0.25] \
                 --convergence 1000x500x250 \
                 --smoothing-sigmas 2x1x0 \
                 --shrink-factors 4x2x1 \
                 --transform BSplineSyN[0.1,6x6x3,0,3] \
                 --metric CC[${fxd},${mvg},1,2] \
                 --convergence 300x270x250 \
                 --smoothing-sigmas 2x1x0 \
                 --shrink-factors 3x2x1"

echo $regCmd >&2
echo "" >&2

$regCmd

# compute the warped label map
# i.e., the labebl map of the reference image warped onto the case image
antsApplyTransforms -d 3 -i ${mvg/image/pmask}  -r ${fxd} -n MultiLabel \
    -t ${tform_root}1Warp.nii.gz -t ${tform_root}0GenericAffine.mat -o ${tform_root}lbl_est_${infl_lvl}.mha

done
