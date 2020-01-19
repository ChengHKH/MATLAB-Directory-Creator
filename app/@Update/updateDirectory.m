function updateDirectory( app, directoryName)
    progress = uiprogressdlg( app.generateTestUIFigure, 'Title', 'Updating', 'Message', 'Initialising', 'Cancelable', 'on');

    caseData = readtable( 'case-list.full.csv', 'ReadVariableNames', true, ...
    'TextType', 'string', 'Format', '%s%s%s%s%s%s%s%s');

    newDirectoryStructure = readtable( fullfile( 'existingDirectory', [directoryName '.csv']), 'ReadVariableNames', false);
    newPaths = initialise( newDirectoryStructure, directoryName);
    oldDirectoryStructure = readtable( fullfile( 'existingDirectory', [directoryName '.old.csv']), 'ReadVariableNames', false);
    oldPaths = initialise( oldDirectoryStructure, directoryName);
    
    pathsToRemove = setdiff( oldPaths, newPaths);
    pathsToAdd = setdiff( newPaths, oldPaths);
    
    filePathsToRemove = pathsToRemove( contains( pathsToRemove, 'Files'));
    filePathsToAdd = pathsToAdd( contains( pathsToAdd, 'Files'));

    folderPathsToRemove = pathsToRemove( ~contains( pathsToRemove, 'Files') & ~contains( pathsToRemove, 'Scripts'));
    folderPathsToRemove =  simplifyPaths( 'remove', folderPathsToRemove);
    folderPathsToAdd = pathsToAdd( ~contains( pathsToAdd, 'Files') & ~contains( pathsToAdd, 'Scripts'));
    folderPathsToAdd = simplifyPaths( 'add', folderPathsToAdd);
    
    scriptPathsToUpdate = newPaths( contains( newPaths, 'Scripts'));
    scriptPathsToRemove = pathsToRemove( contains( pathsToRemove, 'Scripts'));
    
    for row = 1:height( caseData)
        caseID = caseData.CaseID{row};
        progress.Value = row / height( caseData);
        if progress.CancelRequested
            break
        end
        
        if ~isempty( pathsToRemove)
            progress.Message = ['Case' caseID ': Removing redundant directories'];
            if ~isempty( filePathsToRemove); processFile( 'remove', filePathsToRemove); end
            if ~isempty( folderPathsToRemove); processFolder( 'remove', folderPathsToRemove); end
        end
        
        if ~isempty( pathsToAdd)
            progress.Message = ['Case' caseID ': Adding missing directories'];
            if ~isempty( folderPathsToAdd); processFolder( 'add', folderPathsToAdd); end
            if ~isempty( filePathsToAdd); processFile( 'add', filePathsToAdd); end
        end
        
        progress.Message = ['Case' caseID ': Updating scripts'];
        processScript( 'remove', scriptPathsToRemove);
        processScript( 'update', scriptPathsToUpdate);

    end
    
    close( progress);
    
    
    function processFile( processType, filePaths)
        
        for ref_row = 1:height( caseData)
            refID = caseData.CaseID{ref_row};
            refFolder = ['ref_' refID];
            
            paths = replace( filePaths, {'caseID', 'refID'}, {caseID, refFolder});
            casePaths = paths( contains( paths, 'case'));
            refPaths = paths( contains( paths, 'ref'));
            
            for lvl = ["frc+bag", "tlc", "rv"]
                antsImageFile = [char(lvl) '_image.mha'];
                antsMaskFile = [char(lvl) '_pmask.mha'];
                niftyImageCase = [char(lvl) '_image.nii.gz'];
                niftyMaskCase = [char(lvl) '_pmask.nii.gz'];
            
                if isequal( caseID, refID)
                    antsPaths = regexprep( casePaths, 'case\w*Files', char(lvl));
                    niftyPaths = regexprep( casePaths, 'case\w*Files', [char(lvl) '_nifty']);
                    
                    if isequal( processType, 'remove')
                        
                        for index = 1:length( casePaths)
                            system( ['rm -r ' antsPaths{index}]);
                            system( ['rm -r ' niftyPaths{index}]);
                        end
                        
                    elseif isequal( processType, 'add')
                        
                        for index = 1:length( casePaths)
                            mkdir( antsPaths{index});
                            mkdir( niftyPaths{index});
                            
                            relative = repmat( {'..'}, 1, length( split(casePaths{index}, filesep)));
                            sourcePath = fullfile( relative{:}, directoryName, ['cases' regexp( casePaths{index}, '(?<=case)\w*(?=Files)', 'match', 'once')], caseID);
                            
                            system( ['ln -s ' fullfile( sourcePath, char(lvl), antsImageFile) ' ' fullfile( antsPaths{index}, antsImageFile)]);
                            system( ['ln -s ' fullfile( sourcePath, char(lvl), antsMaskFile) ' ' fullfile( antsPaths{index}, antsMaskFile)]);
                            system( ['ln -s ' fullfile( sourcePath, [char(lvl) '_nifty'], niftyImageFile) ' ' fullfile( niftyPaths{index}, niftyImageCase)]);
                            system( ['ln -s ' fullfile( sourcePath, [char(lvl) '_nifty'], niftyImageFile) ' ' fullfile( niftyPaths{index}, niftyMaskCase)]);
                            
                        end
                        
                    end
                    
                elseif ~isequal(caseID, refID)
                    antsPaths = regexprep( refPaths, 'ref\w*Files', char(lvl));
                    niftyPaths = regexprep( refPaths, 'ref\w*Files', [char(lvl) '_nifty']);
                    
                    if isequal( processType, 'remove')
                        
                        for index = 1:length( refPaths)
                            system( ['rm -r ' antsPaths{index}]);
                            system( ['rm -r ' niftyPaths{index}]);
                        end
                        
                    elseif isequal( processType, 'add')
                        
                        for index = 1:length( refPaths)
                            mkdir( antsPaths{index});
                            mkdir( niftyPaths{index});
                            
                            relative = repmat( {'..'}, 1, length( split(filePaths.base{index}, filesep)));
                            sourcePath = fullfile( relative{:}, ['cases' regexp( casePaths{index}, '(?<=case)\w*(?=Files)', 'match', 'once')], refID);
                            
                            system( ['ln -s ' fullfile( sourcePath, char(lvl), antsImageFile) ' ' fullfile( antsPaths{index}, antsImageFile)]);
                            system( ['ln -s ' fullfile( sourcePath, char(lvl), antsMaskFile) ' ' fullfile( antsPaths{index}, antsMaskFile)]);
                            system( ['ln -s ' fullfile( sourcePath, [char(lvl) '_nifty'], niftyImageFile) ' ' fullfile( niftyPaths{index}, niftyImageCase)]);
                            system( ['ln -s ' fullfile( sourcePath, [char(lvl) '_nifty'], niftyImageFile) ' ' fullfile( niftyPaths{index}, niftyMaskCase)]);
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
    end

    function processFolder( processType, folderPaths)
        
        for ref_row = 1:height( caseData)
            refID = caseData.CaseID{ref_row};
            refFolder = ['ref_' refID];
            
            paths = replace( folderPaths, {'caseID', 'refID'}, {caseID, refFolder});
            casePaths = paths( ~contains( folderPaths, 'ref'));
            refPaths = paths( contains( folderPaths, 'ref'));
            
            if isequal( caseID, refID)
                
                if isequal( processType, 'remove')
                    
                    for index = 1:length( refPaths)
                        rmdir( casePaths{index});
                    end
                    
                elseif isequal( processType, 'add')
                    
                    for index = 1:length( casePaths)
                        mkdir( casePaths{index});
                    end
                    
                end
                
            elseif ~isequal( caseID, refID)
                
                if isequal( processType, 'remove')
                    
                    for index = 1:length( refPaths)
                        rmdir( refPaths{index});
                    end
                    
                elseif isequal( processType, 'add')
                    
                    for index = 1:length( casePaths)
                        mkdir( refPaths{index});
                    end
                    
                end
                
            end
            
        end
        
    end

    function processScript( processType, scriptPaths)
        scriptsDir = fullfile( directoryName, 'scripts');
        
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
                        if isequal( processType, 'remove')
                            delete( regexprep( casePaths{index}, 'do\w*Scripts', scripts( list).name));
                        elseif isequal( processType, 'update')
                            copyfile( fullfile( scriptsDir, scripts( list).name), regexprep( casePaths{index}, 'do\w*Scripts', scripts( list).name));
                        end
                    end
                    
                end
                
            elseif ~isequal( caseID, refID)
                
                for index = 1:length( refPaths)
                    scriptType = regexp( refPaths{index}, '(?<=do)\w*(?=Scripts)', 'match', 'once');
                    scripts = dir( fullfile( scriptsDir, ['do*' scriptType '*']));
                    
                    for list = 1:length( scripts)
                        if isequal( processType, 'remove')
                            delete( regexprep( casePaths{index}, 'do\w*Scripts', scripts( list).name));
                        elseif isequal( processType, 'update')
                            copyfile( fullfile( scriptsDir, scripts( list).name), regexprep( casePaths{index}, 'do\w*Scripts', scripts( list).name));
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
    end

end

function paths = initialise( directoryStructure, directoryName)
    defaultStructure = readtable( fullfile( 'directoryStructures', 'CreateNewStructureDefault.csv'), 'ReadVariableNames', false);
    
    for row = 1:height( directoryStructure)
       directory{row,1} = fullfile( directoryName, directoryStructure{row,:}{:});
    end
    for row = 1:height( defaultStructure)
        default{row,1} = fullfile( directoryName, defaultStructure{row,:}{:});
    end
    
    paths = setdiff( directory, default);
    
end

function outPaths = simplifyPaths( simplifyType, inPaths)
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
        
        if isequal( simplifyType, 'remove')
            simplifiedPaths = [simplifiedPaths; inPaths(1)];
            inPaths = inPaths( ~tf);
        elseif isequal( simplifyType, 'add')
            if sum( tf) == 1
                simplifiedPaths = [simplifiedPaths; inPaths(1)];
                inPaths = inPaths( ~tf);
            else
                inPaths(1,:) = [];
            end
        end
        
    end
    
    outPaths = table2cell( simplifiedPaths);
    
end