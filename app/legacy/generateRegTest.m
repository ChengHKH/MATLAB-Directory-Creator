caseData = readtable( 'case-list.full.csv', 'ReadVariableNames', true, ...
    'TextType', 'string', 'Format', '%s%s%s%s%s%s%s%s');

i = 1;
while exist( sprintf( 'test%i', i), 'dir')
    i = i + 1;
end
mkdir (sprintf( 'test%i', i));
cd (sprintf( 'test%i', i));

mkdir( 'cases');
create( caseData,'cases');

mkdir( 'output');
create( caseData,'output');

mkdir( 'scripts');

function create( caseData,folder)
for row = 1:height( caseData)
    caseID = caseData.CaseID{row};
    caseDir = caseData.CaseDir{row};
    tlcImage = caseData.tlc_image_path{row};
    tlcMask = caseData.tlc_mask_path{row};
    frcImage = caseData.frc_image_path{row};
    frcMask = caseData.frc_mask_path{row};
    rvImage = caseData.rv_image_path{row};
    rvMask = caseData.rv_mask_path{row};
        
    if isequal(folder,'cases')
        mkdir( fullfile( folder,caseID));
        
        for column = 3:width( caseData)
            file = char(caseData{row,column});
            path = fullfile('../../../../../',file);

            if isequal( file,tlcImage)
                fileName = 'tlc_image.mha';
            elseif isequal( file,tlcMask)
                fileName = 'tlc_pmask.mha';
            elseif isequal( file,frcImage)
                fileName = 'frc+bag_image.mha';
            elseif isequal( file,frcMask)
                fileName = 'frc+bag_pmask.mha';
            elseif isequal( file,rvImage)
                fileName = 'rv_image.mha';
            elseif isequal( file,rvMask)
                fileName = 'rv_pmask.mha';
            end
        
            pathNew = fullfile(folder,caseID,fileName);
            command = ['ln -s ' path ' ' pathNew];
            system( command);
        
        end
        
        if row == 1
            caselist = struct( 'CaseID',cell(23,1), 'Include',cell(23,1));
        end
        
        caselist( row,1).CaseID = caseID;
        caselist( row,1).Include = true;
        
        if row == height( caseData)
            writetable( struct2table( caselist),'caseList.csv');
        end
        
    elseif isequal(folder,'output')
        mkdir( fullfile( folder,caseID));
        mkdir( fullfile( folder,caseID,'tlc2rv'));
        mkdir( fullfile( folder,caseID,'frc2rv'));
    
    end
    
end

end