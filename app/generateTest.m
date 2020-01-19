classdef generateTest < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        generateTestUIFigure         matlab.ui.Figure
        TabGroup                     matlab.ui.container.TabGroup
        CreateTab                    matlab.ui.container.Tab
        GridLayout                   matlab.ui.container.GridLayout
        CreateLeftPanel              matlab.ui.container.Panel
        DirectoryNameEditFieldLabel  matlab.ui.control.Label
        DirectoryNameEditField       matlab.ui.control.EditField
        DirectoryTypeDropDownLabel   matlab.ui.control.Label
        DirectoryTypeDropDown        matlab.ui.control.DropDown
        CreateButton                 matlab.ui.control.Button
        CreateRightPanel             matlab.ui.container.Panel
        CreateDirectoryOutline       matlab.ui.container.Tree
        DirectoryOutlineLabel        matlab.ui.control.Label
        UpdateTab                    matlab.ui.container.Tab
        GridLayout2                  matlab.ui.container.GridLayout
        UpdateRightPanel             matlab.ui.container.Panel
        DirectoryDropDownLabel       matlab.ui.control.Label
        DirectoryDropDown            matlab.ui.control.DropDown
        UpdateButton                 matlab.ui.control.Button
        UpdateLeftPanel              matlab.ui.container.Panel
        UpdateDirectoryOutline       matlab.ui.container.Tree
        DirectoryOutlineLabel_2      matlab.ui.control.Label
    end

    
    properties (Access = private)
        NewStructureApp
        UpdateApp
        DirectoryType
        DirectoryName
        CreateDirectoryOutlineDirectory = ''
        CreateDirectoryStructure
        UpdateDirectoryStructure
        
    end
    
    methods (Access = public)
        
        function generateDisplayFcn(app)
            app.DirectoryType = app.DirectoryTypeDropDown.Value( ~isspace( app.DirectoryTypeDropDown.Value));
            app.CreateDirectoryStructure = readtable( fullfile( 'directoryStructures', [app.DirectoryType '.csv']), 'ReadVariableNames', false);
            Node.Directory = uitreenode( app.CreateDirectoryOutline, 'Text', app.CreateDirectoryOutlineDirectory);
            
            for row = 1:height( app.CreateDirectoryStructure)
                pathFolders = app.CreateDirectoryStructure{row,:}( ~cellfun( 'isempty',app.CreateDirectoryStructure{row,:}));
                
                if isequal( pathFolders{1}, pathFolders{end})
                    Node.( pathFolders{end}) = uitreenode( Node.Directory, 'Text', pathFolders{end});
                else
                    Node.( [pathFolders{1:end}]) = uitreenode( Node.( [pathFolders{1:end - 1}]), 'Text', pathFolders{end});
                end
                
            end
            
            expand( app.CreateDirectoryOutline, 'all')
            
        end
        
        function updateDisplayFcn(app)
            app.DirectoryName = app.DirectoryDropDown.Value;
            app.UpdateDirectoryStructure = readtable( fullfile( 'existingDirectory', [app.DirectoryName '.csv']), 'ReadVariableNames', false);
            Node.Directory = uitreenode( app.UpdateDirectoryOutline, 'Text', app.DirectoryName);
            
            for row = 1:height( app.UpdateDirectoryStructure)
                pathFolders = app.UpdateDirectoryStructure{row,:}( ~cellfun( 'isempty',app.UpdateDirectoryStructure{row,:}));
                
                if isequal( pathFolders{1}, pathFolders{end})
                    Node.( pathFolders{end}) = uitreenode( Node.Directory, 'Text', pathFolders{end});
                else
                    Node.( [pathFolders{1:end}]) = uitreenode( Node.( [pathFolders{1:end - 1}]), 'Text', pathFolders{end});
                end
                
            end
            
            expand( app.UpdateDirectoryOutline, 'all')
            
        end
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            generateDisplayFcn(app);
            try updateDisplayFcn(app); end
        end

        % Value changed function: DirectoryNameEditField
        function DirectoryNameEditFieldValueChanged(app, event)
            app.CreateDirectoryOutlineDirectory = app.DirectoryNameEditField.Value;
            delete(app.CreateDirectoryOutline.Children);
            generateDisplayFcn(app);
        end
        
        % Value changed function: DirectoryTypeDropDown
        function DirectoryTypeDropDownValueChanged(app, event)
            if isequal( app.DirectoryTypeDropDown.Value,'New Structure')
                delete(app.CreateDirectoryOutline.Children);
                app.DirectoryTypeDropDown.Enable = 'off';
                app.NewStructureApp = NewStructure(app);
            else
                delete(app.CreateDirectoryOutline.Children);
                generateDisplayFcn(app);
            end
        end

        % Button pushed function: CreateButton
        function CreateButtonPushed(app, event)
            createDirectory( app, app.DirectoryNameEditField.Value, app.DirectoryType);
            copyfile( fullfile( 'directoryStructures', [app.DirectoryType '.csv']), fullfile( 'existingDirectory', [app.DirectoryName '.csv']));
        end

        % Value changed function: DirectoryDropDown
        function DirectoryDropDownValueChanged(app, event)
            delete(app.UpdateDirectoryOutline.Children);
            updateDisplayFcn(app);
        end

        % Button pushed function: UpdateButton
        function UpdateButtonPushed(app, event)
            app.DirectoryDropDown.Enable = 'off';
            app.UpdateApp = Update( app, app.DirectoryName);
        end
        
        % Close request function: generateTestUIFigure
        function generateTestUIFigureCloseRequest(app, event)
            delete( app.NewStructureApp);
            delete( app.UpdateApp);
            delete( app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create generateTestUIFigure and hide until all components are created
            app.generateTestUIFigure = uifigure('Visible', 'off');
            app.generateTestUIFigure.Position = [100 100 420 210];
            app.generateTestUIFigure.Name = 'generateTest';
            app.generateTestUIFigure.CloseRequestFcn = createCallbackFcn(app, @generateTestUIFigureCloseRequest, true);

            % Create TabGroup
            app.TabGroup = uitabgroup(app.generateTestUIFigure);
            app.TabGroup.Position = [1 1 420 210];

            % Create CreateTab
            app.CreateTab = uitab(app.TabGroup);
            app.CreateTab.Title = 'Create';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.CreateTab);
            app.GridLayout.ColumnWidth = {160, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];

            % Create CreateLeftPanel
            app.CreateLeftPanel = uipanel(app.GridLayout);
            app.CreateLeftPanel.Layout.Row = 1;
            app.CreateLeftPanel.Layout.Column = 1;
            
            % Create DirectoryNameEditFieldLabel
            app.DirectoryNameEditFieldLabel = uilabel(app.CreateLeftPanel);
            app.DirectoryNameEditFieldLabel.Position = [20 151 120 22];
            app.DirectoryNameEditFieldLabel.Text = 'Directory Name:';

            % Create DirectoryNameEditField
            app.DirectoryNameEditField = uieditfield(app.CreateLeftPanel, 'text');
            app.DirectoryNameEditField.ValueChangedFcn = createCallbackFcn(app, @DirectoryNameEditFieldValueChanged, true);
            app.DirectoryNameEditField.Position = [20 131 120 22];
            
            % Create DirectoryTypeDropDownLabel
            app.DirectoryTypeDropDownLabel = uilabel(app.CreateLeftPanel);
            app.DirectoryTypeDropDownLabel.Position = [20 91 120 22];
            app.DirectoryTypeDropDownLabel.Text = 'Directory Type:';

            % Create DirectoryTypeDropDown
            app.DirectoryTypeDropDown = uidropdown(app.CreateLeftPanel);
            app.DirectoryTypeDropDown.Items = table2cell(readtable( fullfile('directoryStructures','DirectoryTypeList.csv'), 'ReadVariable', false, 'Delimiter', '\n'))';
            app.DirectoryTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @DirectoryTypeDropDownValueChanged, true);
            app.DirectoryTypeDropDown.Position = [20 71 120 22];
            app.DirectoryTypeDropDown.Value = app.DirectoryTypeDropDown.Items{1};

            % Create CreateButton
            app.CreateButton = uibutton(app.CreateLeftPanel, 'push');
            app.CreateButton.ButtonPushedFcn = createCallbackFcn(app, @CreateButtonPushed, true);
            app.CreateButton.Position = [30 23 100 22];
            app.CreateButton.Text = 'Create';

            % Create CreateRightPanel
            app.CreateRightPanel = uipanel(app.GridLayout);
            app.CreateRightPanel.Layout.Row = 1;
            app.CreateRightPanel.Layout.Column = 2;

            % Create CreateDirectoryOutline
            app.CreateDirectoryOutline = uitree(app.CreateRightPanel);
            app.CreateDirectoryOutline.Position = [20 23 220 129];

            % Create DirectoryOutlineLabel
            app.DirectoryOutlineLabel = uilabel(app.CreateRightPanel);
            app.DirectoryOutlineLabel.Position = [20 151 99 22];
            app.DirectoryOutlineLabel.Text = 'Directory Outline:';

            % Create UpdateTab
            app.UpdateTab = uitab(app.TabGroup);
            app.UpdateTab.Title = 'Update';

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.UpdateTab);
            app.GridLayout2.ColumnWidth = {160, '1x'};
            app.GridLayout2.RowHeight = {'1x'};
            app.GridLayout2.ColumnSpacing = 0;
            app.GridLayout2.RowSpacing = 0;
            app.GridLayout2.Padding = [0 0 0 0];

            % Create UpdateRightPanel
            app.UpdateRightPanel = uipanel(app.GridLayout2);
            app.UpdateRightPanel.Layout.Row = 1;
            app.UpdateRightPanel.Layout.Column = 1;

            % Create DirectoryDropDownLabel
            app.DirectoryDropDownLabel = uilabel(app.UpdateRightPanel);
            app.DirectoryDropDownLabel.Position = [21 121 120 22];
            app.DirectoryDropDownLabel.Text = 'Directory:';

            % Create DirectoryDropDown
            app.DirectoryDropDown = uidropdown(app.UpdateRightPanel);
            
            existingDirectoryList = {};
            existingDirectory = dir( fullfile( 'existingDirectory', '*.csv'));
            existingDirectory = existingDirectory( ~contains( {existingDirectory.name}, '.old.csv'));
            for row = 1:length( existingDirectory)
                [~, directoryName, ext] = fileparts( existingDirectory(row).name);
                
                if isequal( ext, '.csv')
                   existingDirectoryList = [existingDirectoryList directoryName];
                else
                end
            end
            
            app.DirectoryDropDown.Items = existingDirectoryList;
            app.DirectoryDropDown.ValueChangedFcn = createCallbackFcn(app, @DirectoryDropDownValueChanged, true);
            app.DirectoryDropDown.Position = [21 100 120 22];
            
            if isempty( app.DirectoryDropDown.Items)
                app.DirectoryDropDown.Value = {};
            else
                app.DirectoryDropDown.Value = app.DirectoryDropDown.Items{1};
            end

            % Create UpdateButton
            app.UpdateButton = uibutton(app.UpdateRightPanel, 'push');
            app.UpdateButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateButtonPushed, true);
            app.UpdateButton.Position = [31 51 100 22];
            app.UpdateButton.Text = 'Select';

            % Create UpdateLeftPanel
            app.UpdateLeftPanel = uipanel(app.GridLayout2);
            app.UpdateLeftPanel.Layout.Row = 1;
            app.UpdateLeftPanel.Layout.Column = 2;

            % Create UpdateDirectoryOutline
            app.UpdateDirectoryOutline = uitree(app.UpdateLeftPanel);
            app.UpdateDirectoryOutline.Position = [20 23 220 129];

            % Create DirectoryOutlineLabel_2
            app.DirectoryOutlineLabel_2 = uilabel(app.UpdateLeftPanel);
            app.DirectoryOutlineLabel_2.Position = [20 151 99 22];
            app.DirectoryOutlineLabel_2.Text = 'Directory Outline:';

            % Show the figure after all components are created
            app.generateTestUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = generateTest

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.generateTestUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.generateTestUIFigure)
        end
    end
end