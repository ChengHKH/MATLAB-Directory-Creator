classdef NewStructure < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        NewStructureUIFigure         matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        NewStructureLeftPanel        matlab.ui.container.Panel
        DirectoryTypeEditFieldLabel  matlab.ui.control.Label
        DirectoryTypeEditField       matlab.ui.control.EditField
        DirectoryStructureTextAreaLabel  matlab.ui.control.Label
        DirectoryStructureTextArea   matlab.ui.control.TextArea
        TestLabel                    matlab.ui.control.Label
        ConfirmButton                matlab.ui.control.Button
        NewStructureRightPanel       matlab.ui.container.Panel
        DirectoryOutline             matlab.ui.container.Tree
        DirectoryOutlineLabel        matlab.ui.control.Label
    end

    
    properties (Access = private)
        MainApp
        DirectoryTypeName = ' Test';
        DefaultStructure = readtable( fullfile('directoryStructures','CreateNewStructureDefault.csv'), 'ReadVariableNames', false);
        DirectoryStructure = readtable( fullfile('directoryStructures','CreateNewStructureDirectory.csv'), 'ReadVariableNames', false);
        OutlineStructure
        DirectoryTypeList
    end
    
    methods (Access = private)
        
        function NewStructureDisplayFcn(app)
            for row = 1:height( app.DirectoryStructure)
                structure{row} = strjoin( app.DirectoryStructure{row,:}( ~cellfun( 'isempty', app.DirectoryStructure{row,:})), ',');
            end
            
            app.DirectoryStructureTextArea.Value = structure;
            
            Node.DirectoryType = uitreenode( app.DirectoryOutline, 'Text', app.DirectoryTypeName);
            
            for row = 1:height( app.OutlineStructure)
                pathFolders = app.OutlineStructure{row,:}( ~cellfun( 'isempty',app.OutlineStructure{row,:}));
                
                if isequal( pathFolders{1}, pathFolders{end})
                    Node.( pathFolders{end}) = uitreenode( Node.DirectoryType, 'Text', pathFolders{end});
                else
                    try
                        Node.( [pathFolders{1:end}]) = uitreenode( Node.( [pathFolders{1:end - 1}]), 'Text', pathFolders{end});
                    catch
                        app.DirectoryStructureTextArea.Value{end + 1} = strjoin( pathFolders(1:end - 1), ',');
                        DirectoryStructureTextAreaValueChanged(app, true);
                        break
                    end
                    
                end
                
            end
            
            expand( app.DirectoryOutline, 'all')
            
        end
        
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp)
            app.MainApp = mainapp;
            app.DirectoryTypeList = table2cell(readtable( fullfile('directoryStructures','DirectoryTypeList.csv'), 'ReadVariableNames', false, 'Delimiter', '\n'));
            app.OutlineStructure = sortrows( outerjoin( app.DefaultStructure, app.DirectoryStructure, 'MergeKeys', true));

            NewStructureDisplayFcn(app);
        end

        % Value changed function: DirectoryStructureTextArea
        function DirectoryStructureTextAreaValueChanged(app, event)
            structureText = app.DirectoryStructureTextArea.Value( ~cellfun( 'isempty', app.DirectoryStructureTextArea.Value));
            for row = 1:length( structureText)
                structure{row,1} = split( structureText{row}, ',')';
            end
            
            defaultStructure = table2cell( app.DefaultStructure);
            
            len = max( [cellfun(@length, structure); width( app.DefaultStructure)]);
            
            for row = 1:length( structureText)
                structure{row,1}(end + 1:len) = {''};
            end
            
            for row = 1:height( app.DefaultStructure)
               defaultStructure(row, width( app.DefaultStructure) + 1:len) = {''}; 
            end
            
            structure = vertcat( structure{:});
            
            app.DirectoryStructure = sortrows( cell2table( structure));
            app.OutlineStructure = sortrows( cell2table( [defaultStructure; structure]));
            
            delete( app.DirectoryOutline.Children);
            NewStructureDisplayFcn( app);
            
        end

        % Value changed function: DirectoryTypeEditField
        function DirectoryTypeEditFieldValueChanged(app, event)
            app.DirectoryTypeName = [app.DirectoryTypeEditField.Value ' Test'];
            delete( app.DirectoryOutline.Children);
            NewStructureDisplayFcn( app);
        end

        % Button pushed function: ConfirmButton
        function ConfirmButtonPushed(app, event)
            if exist( fullfile( 'directoryStructures', [app.DirectoryTypeName( ~isspace( app.DirectoryTypeName)) '.csv']), 'file')
                msg = ['Directory structure for ' app.DirectoryTypeName ' already exists.'];
                options = {'Overwrite', 'Save As New', 'Cancel'};
                selection = uiconfirm( app.NewStructureUIFigure, msg, 'Confirm', 'Options', options, 'DefaultOption', 2, 'Icon', 'warning');
                
                if isequal( selection, options{2})
                    n = 1;
                    while exist( fullfile( 'directoryStructures', [app.DirectoryTypeName( ~isspace( app.DirectoryTypeName)) n '.csv']), 'file')
                        n = n + 1;
                    end
                    app.DirectoryTypeName = [app.DirectoryTypeName ' ' sprintf('%i',n)];
                elseif isequal( selection, options{3})
                    return;
                    
                end
                
            end
            
            writetable( app.OutlineStructure, fullfile( 'directoryStructures', [app.DirectoryTypeName( ~isspace( app.DirectoryTypeName)) '.csv']), 'WriteVariableNames', false);
            
            app.DirectoryTypeList{end} = app.DirectoryTypeName;
            [app.DirectoryTypeList, index] = sortrows( app.DirectoryTypeList);
            app.DirectoryTypeList{end + 1} = 'New Structure';
            writetable( cell2table( app.DirectoryTypeList), fullfile( 'directoryStructures', 'DirectoryTypeList.csv'), 'WriteVariableNames', false);
            
            app.MainApp.DirectoryTypeDropDown.Items = table2cell(readtable( fullfile('directoryStructures','DirectoryTypeList.csv'), 'ReadVariable', false, 'Delimiter', '\n'))';
            app.MainApp.DirectoryTypeDropDown.Value = app.MainApp.DirectoryTypeDropDown.Items{ find( index == length(app.DirectoryTypeList) - 1)};
            app.MainApp.DirectoryTypeDropDown.Enable = 'on';
            generateDisplayFcn( app.MainApp);
            delete(app);
            
        end

        % Close request function: NewStructureUIFigure
        function NewStructureUIFigureCloseRequest(app, event)
            app.MainApp.DirectoryTypeDropDown.Enable = 'on';
            app.MainApp.DirectoryTypeDropDown.Value = app.MainApp.DirectoryTypeDropDown.Items{1};
            generateDisplayFcn(app.MainApp);
            delete(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create NewStructureUIFigure and hide until all components are created
            app.NewStructureUIFigure = uifigure('Visible', 'off');
            app.NewStructureUIFigure.Position = [100 100 420 260];
            app.NewStructureUIFigure.Name = 'New Structure';
            app.NewStructureUIFigure.CloseRequestFcn = createCallbackFcn(app, @NewStructureUIFigureCloseRequest, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.NewStructureUIFigure);
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];

            % Create NewStructureLeftPanel
            app.NewStructureLeftPanel = uipanel(app.GridLayout);
            app.NewStructureLeftPanel.Layout.Row = 1;
            app.NewStructureLeftPanel.Layout.Column = 1;

            % Create DirectoryTypeEditFieldLabel
            app.DirectoryTypeEditFieldLabel = uilabel(app.NewStructureLeftPanel);
            app.DirectoryTypeEditFieldLabel.Position = [22 227 86 22];
            app.DirectoryTypeEditFieldLabel.Text = 'Directory Type:';

            % Create DirectoryTypeEditField
            app.DirectoryTypeEditField = uieditfield(app.NewStructureLeftPanel, 'text');
            app.DirectoryTypeEditField.ValueChangedFcn = createCallbackFcn(app, @DirectoryTypeEditFieldValueChanged, true);
            app.DirectoryTypeEditField.Position = [21 207 135 22];

            % Create DirectoryStructureTextAreaLabel
            app.DirectoryStructureTextAreaLabel = uilabel(app.NewStructureLeftPanel);
            app.DirectoryStructureTextAreaLabel.Position = [21 167 110 22];
            app.DirectoryStructureTextAreaLabel.Text = 'Directory Structure:';

            % Create DirectoryStructureTextArea
            app.DirectoryStructureTextArea = uitextarea(app.NewStructureLeftPanel);
            app.DirectoryStructureTextArea.ValueChangedFcn = createCallbackFcn(app, @DirectoryStructureTextAreaValueChanged, true);
            app.DirectoryStructureTextArea.Position = [21 60 170 109];

            % Create TestLabel
            app.TestLabel = uilabel(app.NewStructureLeftPanel);
            app.TestLabel.HorizontalAlignment = 'center';
            app.TestLabel.FontColor = [0.149 0.149 0.149];
            app.TestLabel.Enable = 'off';
            app.TestLabel.Position = [156 207 35 22];
            app.TestLabel.Text = 'Test';

            % Create ConfirmButton
            app.ConfirmButton = uibutton(app.NewStructureLeftPanel, 'push');
            app.ConfirmButton.ButtonPushedFcn = createCallbackFcn(app, @ConfirmButtonPushed, true);
            app.ConfirmButton.Position = [55 20 100 22];
            app.ConfirmButton.Text = 'Confirm';

            % Create NewStructureRightPanel
            app.NewStructureRightPanel = uipanel(app.GridLayout);
            app.NewStructureRightPanel.Layout.Row = 1;
            app.NewStructureRightPanel.Layout.Column = 2;

            % Create DirectoryOutline
            app.DirectoryOutline = uitree(app.NewStructureRightPanel);
            app.DirectoryOutline.Position = [21 20 169 210];

            % Create DirectoryOutlineLabel
            app.DirectoryOutlineLabel = uilabel(app.NewStructureRightPanel);
            app.DirectoryOutlineLabel.Position = [20 228 99 22];
            app.DirectoryOutlineLabel.Text = 'Directory Outline:';

            % Show the figure after all components are created
            app.NewStructureUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = NewStructure(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.NewStructureUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.NewStructureUIFigure)
        end
    end
end