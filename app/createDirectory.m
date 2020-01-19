function createDirectory( app, directoryName, directoryType)
    progress = uiprogressdlg( app.generateTestUIFigure, 'Title', 'Creating', 'Message', 'Initialising', 'Cancelable', 'on');
    
    caseData = readtable( 'case-list.full.csv', 'ReadVariableNames', true, ...
        'TextType', 'string', 'Format', '%s%s%s%s%s%s%s%s');

    directoryStructure = readtable( fullfile( 'directoryStructures', [directoryType '.csv']), 'ReadVariableNames', false);
    for row = 1:height( directoryStructure)
       directoryPaths{row,1} = fullfile( directoryName, directoryStructure{row,:}{:});
    end
    
    folderPaths = directoryPaths( ~contains( directoryPaths, 'Files') & ~contains( directoryPaths, 'Scripts'));
    folderPaths = simplifyPaths( folderPaths);
    
    filePaths = directoryPaths( contains( directoryPaths, 'Files'));
    
    scriptPaths = directoryPaths( contains( directoryPaths, 'Scripts') & ~contains( directoryPaths, 'scripts'));
    
    processFolder( folderPaths);
    processFile( filePaths);
    processScripts( scriptPaths);
    
    close( progress);
    
    function processFolder( folderPaths)
        mkdir( directoryName);
    
        for row = 1:height( caseData)
            caseID = caseData.CaseID{row};
            progress.Value = (1/4) * (row / height( caseData));
            progress.Message = ['Case ' caseID ': Creating folders'];
            if progress.CancelRequested
                break
            end
            
            for ref_row = 1:height( caseData)
                refID = caseData.CaseID{ref_row};
                refFolder = ['ref_' refID];
                
                paths = replace( folderPaths, {'caseID', 'refID'}, {caseID, refFolder});
                casePaths = paths( ~contains( folderPaths, 'ref'));
                refPaths = paths( contains( folderPaths, 'ref'));
                
                if isequal( caseID, refID)
                        
                    for index = 1:length( casePaths)
                        if ~exist( casePaths{index}, 'dir')
                            mkdir( casePaths{index});
                        end
                    end
                    
                elseif ~isequal( caseID, refID)
                        
                    for index = 1:length( refPaths)
                        if ~exist( refPaths{index}, 'dir')
                            mkdir( refPaths{index});
                        end
                    end
                    
                end
                
            end
        
        end
    
    end

    function processFile( filePaths)
        
        sourcePaths = filePaths( contains( filePaths, 'cases'));
        filePaths = filePaths( ~contains( filePaths, 'cases'));
        
        %%creating files
        for row = 1:height( caseData)
            caseID = caseData.CaseID{row};
            tlcImage = caseData.tlc_image_path{row};
            tlcMask = caseData.tlc_mask_path{row};
            frcImage = caseData.frc_image_path{row};
            frcMask = caseData.frc_mask_path{row};
            rvImage = caseData.rv_image_path{row};
            rvMask = caseData.rv_mask_path{row};
            
            paths = replace( sourcePaths, 'caseID', caseID);
            
            progress.Value = (1/4) + ((1/4) * (row / height( caseData)));
            progress.Message = ['Case ' caseID ': Creating files'];
            if progress.CancelRequested
                break
            end
            
            for lvl = ["frc+bag", "tlc", "rv"]
                antsPaths = regexprep( paths, 'case\w*Files', char(lvl));
                niftyPaths = regexprep( paths, 'case\w*Files', [char(lvl) '_nifty']);
                
                for index = 1:length( paths)
                    mkdir( antsPaths{index});
                    mkdir( niftyPaths{index});
                end
                
            end
            
            for column = 3:width( caseData)
                file = char( caseData{row, column});
                relative = repmat( {'..'}, 1, 6);
                source = fullfile(relative{:}, file);
                
                if isequal( file,tlcImage)
                    antsFileName = fullfile( 'tlc', 'tlc_image.mha');
                    niftyFileName = fullfile( 'tlc_nifty', 'tlc_image.nii.gz');
                elseif isequal( file,tlcMask)
                    antsFileName = fullfile( 'tlc', 'tlc_pmask.mha');
                    niftyFileName = fullfile( 'tlc_nifty', 'tlc_pmask.nii.gz');
                elseif isequal( file,frcImage)
                    antsFileName = fullfile( 'frc+bag', 'frc+bag_image.mha');
                    niftyFileName = fullfile( 'frc+bag_nifty', 'frc+bag_image.nii.gz');
                elseif isequal( file,frcMask)
                    antsFileName = fullfile( 'frc+bag', 'frc+bag_pmask.mha');
                    niftyFileName = fullfile( 'frc+bag_nifty', 'frc+bag_pmask.nii.gz');
                elseif isequal( file,rvImage)
                    antsFileName = fullfile( 'rv', 'rv_image.mha');
                    niftyFileName = fullfile( 'rv_nifty', 'rv_image.nii.gz');
                elseif isequal( file,rvMask)
                    antsFileName = fullfile( 'rv', 'rv_pmask.mha');
                    niftyFileName = fullfile( 'rv_nifty', 'rv_pmask.nii.gz');
                end
                
                path = fullfile ( directoryName, 'cases', caseID);
                system( ['ln -s ' source ' ' fullfile( path, antsFileName)]);
                
                system(['c3d ' fullfile( path, antsFileName) ' -type ushort -o ' fullfile( path, niftyFileName)]);
                
            end
            
            if row == 1
                caselist = struct( 'CaseID',cell(23,1), 'Include',cell(23,1));
            end
            
            caselist( row,1).CaseID = caseID;
            caselist( row,1).Include = true;
            
            if row == height( caseData)
                writetable( struct2table( caselist), fullfile( directoryName, 'caseList.csv'));
            end
            
        end
        
        %% preprocessing files
        for index = 1:length( sourcePaths)
            fileType = regexp( sourcePaths{index}, '(?<=case)\w*(?=Files)', 'match', 'once');
            
            if ~isempty( fileType)
                fh = str2func( fileType);
                
                for row = 1:height( caseData)
                    caseID = caseData.CaseID{row};
            
                    progress.Message = ['Case ' caseID ': ' fileType 'ing files'];
                    if progress.CancelRequested
                        break
                    end
                    
                    fh( directoryName, caseID);
                    
                end
            else
            end
        
        end
        
        %% linking files
        for row = 1:height( caseData)
            caseID = caseData.CaseID{row};
            progress.Value = (2/4) + ((1/4) * (row / height( caseData)));
            progress.Message = ['Case ' caseID ': Linking files'];
            if progress.CancelRequested
                break
            end
            
            for ref_row = 1:height( caseData)
                refID = caseData.CaseID{ref_row};
                refFolder = ['ref_' refID];
                
                paths = replace( filePaths, {'caseID', 'refID'}, {caseID, refFolder});
                casePaths = paths( contains( paths, 'case'));
                refPaths = paths( contains( paths, 'ref'));
                
                for lvl = ["frc+bag", "tlc", "rv"]
                    antsImageFile = [char(lvl) '_image.mha'];
                    antsMaskFile = [char(lvl) '_pmask.mha'];
                    niftyImageFile = [char(lvl) '_image.nii.gz'];
                    niftyMaskFile = [char(lvl) '_pmask.nii.gz'];
                    
                    if isequal( caseID, refID)
                        antsPaths = regexprep( casePaths, 'case\w*Files', char(lvl));
                        niftyPaths = regexprep( casePaths, 'case\w*Files', [char(lvl) '_nifty']);
                        
                        for index = 1:length( casePaths)
                            mkdir( antsPaths{index});
                            mkdir( niftyPaths{index});
                            
                            relative = repmat( {'..'}, 1, length( split(casePaths{index}, filesep)));
                            sourcePath = fullfile( relative{:}, directoryName, ['cases' regexp( casePaths{index}, '(?<=case)\w*(?=Files)', 'match', 'once')], caseID);
                            
                            system( ['ln -s ' fullfile( sourcePath, char(lvl), antsImageFile) ' ' fullfile( antsPaths{index}, antsImageFile)]);
                            system( ['ln -s ' fullfile( sourcePath, char(lvl), antsMaskFile) ' ' fullfile( antsPaths{index}, antsMaskFile)]);
                            system( ['ln -s ' fullfile( sourcePath, [char(lvl) '_nifty'], niftyImageFile) ' ' fullfile( niftyPaths{index}, niftyImageFile)]);
                            system( ['ln -s ' fullfile( sourcePath, [char(lvl) '_nifty'], niftyImageFile) ' ' fullfile( niftyPaths{index}, niftyMaskFile)]);
                            
                        end
                           
                    elseif ~isequal(caseID, refID)
                        antsPaths = regexprep( refPaths, 'ref\w*Files', char(lvl));
                        niftyPaths = regexprep( refPaths, 'ref\w*Files', [char(lvl) '_nifty']);
                            
                        for index = 1:length( refPaths)
                            mkdir( antsPaths{index});
                            mkdir( niftyPaths{index});
                            
                            relative = repmat( {'..'}, 1, length( split(refPaths{index}, filesep)));
                            sourcePath = fullfile( relative{:}, ['cases' regexp( casePaths{index}, '(?<=case)\w*(?=Files)', 'match', 'once')], refID);
                            
                            system( ['ln -s ' fullfile( sourcePath, char(lvl), antsImageFile) ' ' fullfile( antsPaths{index}, antsImageFile)]);
                            system( ['ln -s ' fullfile( sourcePath, char(lvl), antsMaskFile) ' ' fullfile( antsPaths{index}, antsMaskFile)]);
                            system( ['ln -s ' fullfile( sourcePath, [char(lvl) '_nifty'], niftyImageFile) ' ' fullfile( niftyPaths{index}, niftyImageFile)]);
                            system( ['ln -s ' fullfile( sourcePath, [char(lvl) '_nifty'], niftyImageFile) ' ' fullfile( niftyPaths{index}, niftyMaskFile)]);
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
            
    end

    function processScripts( scriptPaths)
        
        scriptsDir = fullfile( directoryName, 'scripts');
        
        scripts = dir( 'do*');
        
        for list = 1:length( scripts)
            copyfile( scripts( list).name, scriptsDir);
        end
        
        for row = 1:height( caseData)
            caseID = caseData.CaseID{row};
            progress.Value = (3/4) + ((1/4) * (row / height( caseData)));
            progress.Message = ['Case ' caseID ': Copying scripts'];
            if progress.CancelRequested
                break
            end
            
            for ref_row = 1:height( caseData)
                refID = caseData.CaseID{ref_row};
                refFolder = ['ref_' refID];
                
                paths = replace( scriptPaths, {'caseID', 'refID'}, {caseID, refFolder});
                casePaths = paths( contains( paths, 'case'));
                refPaths = paths( contains( paths, 'ref'));
                
                if isequal( caseID, refID)
                    
                    for index = 1:length( casePaths)
                        scriptType = regexp( casePaths{index}, '(?<=do)\w*(?=Scripts)', 'match', 'once');
                        scripts = dir( fullfile( scriptsDir, ['do*' scriptType '*']));
                        
                        for list = 1:length( scripts)
                            copyfile( fullfile( scriptsDir, scripts( list).name), regexprep( casePaths{index}, 'do\w*Scripts', scripts( list).name));
                        end
                        
                    end
                    
                elseif ~isequal( caseID, refID)
                    reflist( ref_row,1).RefID = refID;
                
                    for index = 1:length( refPaths)
                        scriptType = regexp( refPaths{index}, '(?<=do)\w*(?=Scripts)', 'match', 'once');
                        scripts = dir( fullfile( scriptsDir, ['do*' scriptType '*']));
                        
                        for list = 1:length( scripts)
                            copyfile( fullfile( scriptsDir, scripts( list).name), regexprep( casePaths{index}, 'do\w*Scripts', scripts( list).name));
                        end
                        
                    end
                    
                end
                
                if ref_row == height( caseData)
                    reflist = reflist(~cellfun(@isempty,{reflist.RefID}));
                    reflistName = fullfile( directoryName, 'scripts', ['reg_tasks+ref_' caseID '.list']);
                    writetable( struct2table( reflist), reflistName, 'WriteVariableNames', false, 'FileType', 'text');
                end
                
            end
                
            end
            
        end
        
    end
    
end

function outPaths = simplifyPaths( inPaths)
    simplifiedPaths = table;

    while ~isempty( inPaths)
        paths = {};
        for row = 1:length( inPaths)
            paths{row,1} = split( inPaths{row}, filesep)';
        end
        
        len = max( cellfun(@length, paths));
        
        for row = 1:length( inPaths)
            paths{row,1}(end + 1:len) = {''};
        end
        
        paths = vertcat( paths{:});
        paths = cell2table( paths);
        
        tf = false( length( inPaths), 1);
        for row = 1:length( inPaths)
            match = strcmp( paths{row,:}, paths{1,:});
            
            if length( paths{1,:}( ~cellfun( 'isempty', paths{1,:}))) == sum ( match(1:length( paths{1,:}( ~cellfun( 'isempty', paths{1,:})))))
                tf(row) = true;
            end
            
        end
        
        if sum( tf) == 1
            simplifiedPaths = [simplifiedPaths; inPaths(1)];
            inPaths = inPaths( ~tf);
        else
            inPaths(1,:) = [];
        end
        
    end
    
    outPaths = table2cell( simplifiedPaths);
    
end
