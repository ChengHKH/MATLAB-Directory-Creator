for infl_lvl in frc+bag tlc rv
do
    echo ${infl_lvl}
    
    ref=../my_data/${infl_lvl}_image.mha
    case=${infl_lvl}/${infl_lvl}_image.mha
    case_lbl=${infl_lvl}/${infl_lvl}_pmask.mha

    c3d ${ref} -type ushort -o ${infl_lvl}_nifty/${infl_lvl}_ref.nii.gz
    c3d ${case} -type ushort -o ${infl_lvl}_nifty/${infl_lvl}_case.nii.gz
    c3d ${case_lbl} -type ushort -o ${infl_lvl}_nifty/${infl_lvl}_case_pmask.nii.gz
    
done


for infl_lvl in frc+bag tlc rv
do
    echo ${infl_lvl}

    c3d ${infl_lvl}_image.mha -type ushort -o ${infl_lvl}_ref.nii.gz

done

for infl_lvl in frc+bag tlc rv ; do echo ${infl_lvl} ; c3d ${infl_lvl}_image.mha -type ushort -o ${infl_lvl}_ref.nii.gz ; done


for infl_lvl in frc+bag tlc rv
do
    echo ${infl_lvl}

    c3d ${infl_lvl}_image.mha -type ushort -o ${infl_lvl}_image.nii.gz
    c3d ${infl_lvl}_pmask.mha -type ushort -o ${infl_lvl}_pmask.nii.gz
    
done