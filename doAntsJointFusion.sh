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
    
    warpedImage=${infl_lvl}/refWarpedToCase.mha
    warpedMask=${infl_lvl}/refM_regTo_caseF_lbl_est_${infl_lvl}.mha

    segCmd="antsJointFusion -d 3 -v 1 \
                            -t my_data/${infl_lvl}_image.mha \
                            -o [mas/lbl_fusion_${infl_lvl}.mha,mas/intensity_fusion_${infl_lvl}.mha,mas/pp_image_${infl_lvl}.mha] \
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
