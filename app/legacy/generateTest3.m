caseData = readtable( 'case-list.full.csv', 'ReadVariableNames', true, ...
    'TextType', 'string', 'Format', '%s%s%s%s%s%s%s%s');

mkdir ( 'test3');
cd ( 'test3');

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

if ~exist( 'casesPreprocessed','dir')
    mkdir( 'casesPreprocessed');
    create( caseData,'casesPreprocessed');
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
        
    elseif isequal( folder, 'casesPreprocessed')
        mkdir( fullfile( folder,caseID));
        
        %preprocessing
        for lvl = ["frc+bag", "tlc", "rv"]
            input_dir = fullfile('cases',caseID);
            output_dir = fullfile('casesPreprocessed',caseID);
            preprocess(lvl,input_dir,output_dir);
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
                    imageFile = [inflation{i} '_image.mha'];
                    maskFile = [inflation{i} '_pmask.mha'];
                    path = fullfile('../../../../../','casesPreprocessed',refID,imageFile);
                    pathNew = fullfile(folder,caseID,'mapping',refFolder,inflation{i},imageFile);
                    command = ['ln -s ' path ' ' pathNew];
                    system( command);
                    path = fullfile('../../../../../','cases',refID,maskFile);
                    pathNew = fullfile(folder,caseID,'mapping',refFolder,inflation{i},maskFile);
                    command = ['ln -s ' path ' ' pathNew];
                    system( command);
                    
                end
                
            elseif isequal(refID,caseID)
                mkdir( fullfile( folder,caseID,'mapping','my_data'));
                
                for i = 1:3
                    imageFile = [inflation{i} '_image.mha'];
                    maskFile = [inflation{i} '_pmask.mha'];
                    path = fullfile('../../../../','casesPreprocessed',caseID,imageFile);
                    pathNew = fullfile(folder,caseID,'mapping','my_data',imageFile);
                    command = ['ln -s ' path ' ' pathNew];
                    system( command);
                    path = fullfile('../../../../','cases',caseID,maskFile);
                    pathNew = fullfile(folder,caseID,'mapping','my_data',maskFile);
                    command = ['ln -s ' path ' ' pathNew];
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
        for ref_row = 1:height( caseData)
            refID = caseData.CaseID{ref_row};
            
            if ~isequal(refID,caseID)
                refFolder = ['ref_' refID];
                
                copyfile('scripts/doAtlasInstanceRegistration.sh', ...
                    fullfile( 'output',caseID,'mapping',refFolder));
                copyfile('scripts/doAtlasNiftyRegistration.sh', ...
                    fullfile( 'output',caseID,'mapping',refFolder));
                copyfile('scripts/doTVVF_InstanceReg.sh', ...
                    fullfile( 'output',caseID,'mapping',refFolder));
                
                if ~exist( fullfile( 'output',caseID,'mapping',refFolder,'logs'), 'dir')
                    mkdir( fullfile( 'output',caseID,'mapping',refFolder,'logs'));
                end
                
            end
            
        end
        
    end
    
end

end

function preprocess( lvl, input_dir, output_dir)

imgName = [ char(lvl) '_image.mha'];
origImg = MetaImage.read( fullfile( input_dir, imgName));
pprImg = MetaImage( origImg);

q90 = quantile( origImg.data(:), 0.9);
level = graythresh( min( double( origImg.data) / q90, 1));
newValue = q90 * level;

% thresholding value estimation
rightSideData = origImg.data( :, 1:64, :);
leftSideData = origImg.data( :, 192:256, :);

counts = histcounts( [rightSideData( rightSideData>0); leftSideData( leftSideData>0)], floor(max( origImg.data(:))));
counts(1:20) = 0;
smoothedData = smooth( counts, 71);
[~, cntLoc] = findpeaks( smoothedData, 'NPeaks', 2, 'SortStr', 'descend', ...
    'MinPeakDistance', 71);
cntLoc = sort( cntLoc);
[~, tmpVal] = findpeaks( -1 * smoothedData(cntLoc(1):cntLoc(2)), 'NPeaks', 1);
thrVal = cntLoc(1) + tmpVal;

darkRegion = ~ imbinarize( origImg.data, thrVal);
innerRegion = darkRegion;
for slc = 1:size( innerRegion, 3); innerRegion(:,:,slc) = imclearborder( darkRegion(:,:,slc)); end

borderRegion = darkRegion - innerRegion;
origImg.data( logical(borderRegion)) = newValue;


a = 1085.7408528298274073936529326585;
b = 669.37125128761945538492169264337;
revVal = a - b * log10( double(origImg.data) * 7/60 + 7.5);
pprImg.data = abs( revVal) + 0.9 * min( revVal, 0);
pprImg.saveMetaImage( fullfile( output_dir, imgName));

end