caseData = readtable( 'case-list.full.csv', 'ReadVariableNames', true, ...
    'TextType', 'string', 'Format', '%s%s%s%s%s%s%s%s');

% n = 1;
% while exist( sprintf( 'test%i', n), 'dir')
%     n = n + 1;
% end
% mkdir (sprintf( 'test%i', n));
% cd (sprintf( 'test%i', n));

cd ( 'test2');

if ~exist( 'scripts', 'dir')
    mkdir( 'scripts');
    mkdir( 'scripts/logs');
    copyfile( '../doAtlasInstanceRegistration.sh', 'scripts');
    copyfile( '../doAtlasRegByTask.sh', 'scripts');
    copyfile( '../doAtlasNiftyRegistration.sh', 'scripts');
end

if ~exist( 'cases', 'dir')
    mkdir( 'cases');
    create( caseData, 'cases');
end

if ~exist( 'output', 'dir')
    mkdir( 'output');
    create( caseData, 'output');
end

create( caseData, 'scripts');

function create( caseData, folder)
for row = 1:height( caseData)
    caseID = caseData.CaseID{row};
    caseDir = caseData.CaseDir{row};
    tlcImage = caseData.tlc_image_path{row};
    tlcMask = caseData.tlc_mask_path{row};
    frcImage = caseData.frc_image_path{row};
    frcMask = caseData.frc_mask_path{row};
    rvImage = caseData.rv_image_path{row};
    rvMask = caseData.rv_mask_path{row};
    
    if isequal( folder, 'cases')
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
        
    elseif isequal( folder, 'output')
        mkdir( fullfile( folder,caseID));
        mkdir( fullfile( folder,caseID,'mapping'));
        
        inflation = ["frc+bag" "rv" "tlc"];
        
        for ref_row = 1:height( caseData)
            refID = caseData.CaseID{ref_row};
            
            if ref_row == 1
                reflist = struct( 'RefID',cell(23,1));
            end
            
            if ~isequal(refID,caseID)
                reflist( ref_row,1).RefID = refID;
                refFolder = ['ref_' refID];
                mkdir( fullfile( folder,caseID,'mapping',refFolder));
                
                for i = 1:3
                    mkdir( fullfile( folder,caseID,'mapping',refFolder,inflation{i}));
                    mkdir( fullfile( folder,caseID,'mapping',refFolder, [inflation{i} '_nifty']));
                    imageFile = [inflation{i} '_image.mha'];
                    maskFile = [inflation{i} '_pmask.mha'];
                    path = fullfile('../../../../../','cases',refID,imageFile);
                    pathNew = fullfile(folder,caseID,'mapping',refFolder,inflation{i},imageFile);
                    command = ['ln -s ' path ' ' pathNew];
                    system( command);
                    path = fullfile('../../../../../','cases',refID,maskFile);
                    pathNew = fullfile(folder,caseID,'mapping',refFolder,inflation{i},maskFile);
                    command = ['ln -s ' path ' ' pathNew];
                    system( command);
                    imageCase = [inflation{i} '_case.nii.gz'];
                    maskCase = [inflation{i} '_case_pmask.nii.gz']
                    command = ['c3d ' fullfile(folder,caseID,'mapping',refFolder,inflation{i},imageFile) ' -type ushort -o ' fullfile(folder,caseID,'mapping',refFolder,[inflation{i} '_nifty'],imageCase) ' ; ' ...
                        'c3d ' fullfile(folder,caseID,'mapping',refFolder,inflation{i},maskFile) ' -type ushort -o ' fullfile(folder,caseID,'mapping',refFolder,[inflation{i} '_nifty'],maskCase)]
                    system( command);
                end
                
            elseif isequal(refID,caseID)
                mkdir( fullfile( folder,caseID,'mapping','my_data'));
                
                for i = 1:3
                    imageFile = [inflation{i} '_image.mha'];
                    maskFile = [inflation{i} '_pmask.mha'];
                    path = fullfile('../../../../','cases',caseID,imageFile);
                    pathNew = fullfile(folder,caseID,'mapping','my_data',imageFile);
                    command = ['ln -s ' path ' ' pathNew];
                    system( command);
                    path = fullfile('../../../../','cases',caseID,maskFile);
                    pathNew = fullfile(folder,caseID,'mapping','my_data',maskFile);
                    command = ['ln -s ' path ' ' pathNew];
                    system( command);
                    command = ['c3d ' fullfile(folder,caseID,'mapping','my_data',imageFile) ' -type ushort -o ' fullfile(folder,caseID,'mapping','my_data',imageRef)]
                    system( command);
                end
                
            end
            
            if ref_row == height( caseData)
                reflist = reflist(~cellfun(@isempty,{reflist.RefID}));
                reflistName = ['scripts/reg_tasks+ref_' caseID '.list'];
                writetable( struct2table( reflist), reflistName, 'WriteVariableNames', false, 'FileType', 'text');
            end
            
        end
        
    elseif isequal( folder, 'scripts')
        
        copyfile( 'scripts/doAtlasJF.sh', ...
            fullfile( 'output',caseID,'mapping'));
        copyfile( 'scripts/doNiftyJF.sh', ...
            fullfile( 'output',caseID,'mapping'));
        
        if ~exist( fullfile( 'output',caseID,'mapping','mas'), 'dir')
            mkdir( fullfile( 'output',caseID,'mapping','mas'));
            mkdir( fullfile( 'output',caseID,'mapping','mas_nifty'));
            mkdir( fullfile( 'output',caseID,'mapping','logs'));
        end
        
        for ref_row = 1:height( caseData)
            refID = caseData.CaseID{ref_row};
            
            if ~isequal(refID,caseID)
                refFolder = ['ref_' refID];
                
                copyfile( 'scripts/doAtlasInstanceRegistration.sh', ...
                    fullfile( 'output',caseID,'mapping',refFolder));
                copyfile( 'scripts/doAtlasNiftyRegistration.sh', ...
                    fullfile( 'output',caseID,'mapping',refFolder));
                
                if ~exist( fullfile( 'output',caseID,'mapping',refFolder,'logs'), 'dir')
                    mkdir( fullfile( 'output',caseID,'mapping',refFolder,'logs'));
                end
                
            end
            
        end
        
    end
    
end

end