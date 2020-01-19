#!/bin/bash
#
#$ -l rmem=24G
#$ -l h_rt=10:00:00 
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
    
    warpedImage=${infl_lvl}_nifty/niftyRefWarpedToCaseF3D.nii.gz
    warpedMask=${infl_lvl}_nifty/lbl_est_${infl_lvl}.nii.gz

    segCmd="antsJointFusion -d 3 -v 1 \
                            -t my_data/${infl_lvl}_ref.nii.gz \
                            -o [mas_nifty/lbl_fusion_${infl_lvl}.mha,mas_nifty/intensity_fusion_${infl_lvl}.mha,mas_nifty/pp_image_${infl_lvl}.mha] \
                            -g ref_150083/${warpedImage} -l ref_150083/${warpedMask} \
                            -g ref_150213/${warpedImage} -l ref_150213/${warpedMask} \
                            -g ref_150285/${warpedImage} -l ref_150285/${warpedMask} \
                            -g ref_150293/${warpedImage} -l ref_150293/${warpedMask} \
                            -g ref_150368/${warpedImage} -l ref_150368/${warpedMask} \
                            -p 3x3x1 \
                            -m PC"
                                   
    
echo $segCmd >&2
echo "" >&2

$segCmd


done
