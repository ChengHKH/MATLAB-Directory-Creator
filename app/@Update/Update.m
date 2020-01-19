classdef Update < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UpdateUIFigure              matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout
        UpdateLeftPanel             matlab.ui.container.Panel
        DirectoryStructureTextAreaLabel  matlab.ui.control.Label
        DirectoryStructureTextArea  matlab.ui.control.TextArea
        ConfirmButton               matlab.ui.control.Button
        UpdateRightPanel            matlab.ui.container.Panel
        DirectoryOutline            matlab.ui.container.Tree
        DirectoryOutlineLabel       matlab.ui.control.Label
    end

    properties (Access = private)
        MainApp
        DirectoryName
        DefaultStructure = readtable( fullfile('directoryStructures','CreateNewStructureDefault.csv'), 'ReadVariableNames', false);
        DirectoryStructure
        OutlineStructure
    end
    
    methods (Access = private)
        
        function UpdateDisplayFcn(app)
            for row = 1:height( app.DirectoryStructure)
                structure{row} = strjoin( app.DirectoryStructure{row,:}( ~cellfun( 'isempty',app.DirectoryStructure{row,:})), ',');
            end
            
            app.DirectoryStructureTextArea.Value = structure;
            
            Node.DirectoryType = uitreenode( app.DirectoryOutline, 'Text', app.DirectoryName);
            
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
    
    methods (Access = protected)
        updateDirectory( app, directoryName)
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp, directoryName)
            app.MainApp = mainapp;
            app.DirectoryName = directoryName;
            directoryStructure = readtable( fullfile('existingDirectory', [app.DirectoryName '.csv']), 'ReadVariableNames', false);
            app.DirectoryStructure = setdiff( directoryStructure, app.DefaultStructure);
            app.OutlineStructure = sortrows( outerjoin( app.DefaultStructure, app.DirectoryStructure, 'MergeKeys', true));
            
            UpdateDisplayFcn(app);
        end

        % Value changed function: DirectoryStructureTextArea
        function DirectoryStructureTextAreaValueChanged(app, event)
            structureText = app.DirectoryStructureTextArea.Value( ~cellfun( 'isempty', app.DirectoryStructureTextArea.Value));
            for row = 1:length( structureText)
                structure{row,1} = split( structureText{row}, ',')';
            end
            
            defaultStructure = table2cell( app.DefaultStructure);
            
            len = max( [cellfun(@length, structure); width( app.DefaultStructure)]);
            
            for row = 1:size( structureText)
                structure{row,1}(end + 1:len) = {''};
            end
            
            for row = 1:height( app.DefaultStructure)
               defaultStructure(row, width( app.DefaultStructure) + 1:len) = {''}; 
            end
            
            structure = vertcat( structure{:});
            
            app.DirectoryStructure = sortrows( cell2table( structure));
            app.OutlineStructure = sortrows( cell2table( [defaultStructure; structure]));
            
            delete( app.DirectoryOutline.Children);
            UpdateDisplayFcn( app);
            
        end

        % Button pushed function: ConfirmButton
        function ConfirmButtonPushed(app, event)
            msg = ['You are about to update ' app.DirectoryName '.' newline 'This action is irreversible.' newline 'Do you still wish to continue?'];
            options = {'Continue', 'Cancel'};
            selection = uiconfirm( app.UpdateUIFigure, msg, 'Confirm', 'Options', options, 'DefaultOption', 1, 'Icon', 'warning');
            
            if isequal( selection, options{2})
                return;
            end
            
            copyfile( fullfile( 'existingDirectory', [app.DirectoryName '.csv']), fullfile( 'existingDirectory', [app.DirectoryName '.old.csv']));
            writetable( app.OutlineStructure, fullfile( 'existingDirectory', [app.DirectoryName '.csv']), 'WriteVariableNames', false);
            
            app.updateDirectory( app, app.DirectoryName);
            
            app.MainApp.DirectoryDropDown.Enable = 'on';
            delete(app.MainApp.UpdateDirectoryOutline.Children);
            updateDisplayFcn( app.MainApp);
            delete(app);
            
        end

        % Close request function: UpdateUIFigure
        function UpdateUIFigureCloseRequest(app, event)
            app.MainApp.DirectoryDropDown.Enable = 'on';
            delete(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UpdateUIFigure and hide until all components are created
            app.UpdateUIFigure = uifigure('Visible', 'off');
            app.UpdateUIFigure.Position = [100 100 420 260];
            app.UpdateUIFigure.Name = 'Update';
            app.UpdateUIFigure.CloseRequestFcn = createCallbackFcn(app, @UpdateUIFigureCloseRequest, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UpdateUIFigure);
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];

            % Create UpdateLeftPanel
            app.UpdateLeftPanel = uipanel(app.GridLayout);
            app.UpdateLeftPanel.Layout.Row = 1;
            app.UpdateLeftPanel.Layout.Column = 1;

            % Create DirectoryStructureTextAreaLabel
            app.DirectoryStructureTextAreaLabel = uilabel(app.UpdateLeftPanel);
            app.DirectoryStructureTextAreaLabel.Position = [21 228 110 22];
            app.DirectoryStructureTextAreaLabel.Text = 'Directory Structure:';

            % Create DirectoryStructureTextArea
            app.DirectoryStructureTextArea = uitextarea(app.UpdateLeftPanel);
            app.DirectoryStructureTextArea.ValueChangedFcn = createCallbackFcn(app, @DirectoryStructureTextAreaValueChanged, true);
            app.DirectoryStructureTextArea.Position = [21 60 170 170];

            % Create ConfirmButton
            app.ConfirmButton = uibutton(app.UpdateLeftPanel, 'push');
            app.ConfirmButton.ButtonPushedFcn = createCallbackFcn(app, @ConfirmButtonPushed, true);
            app.ConfirmButton.Position = [55 20 100 22];
            app.ConfirmButton.Text = 'Confirm';

            % Create UpdateRightPanel
            app.UpdateRightPanel = uipanel(app.GridLayout);
            app.UpdateRightPanel.Layout.Row = 1;
            app.UpdateRightPanel.Layout.Column = 2;

            % Create DirectoryOutline
            app.DirectoryOutline = uitree(app.UpdateRightPanel);
            app.DirectoryOutline.Position = [21 20 169 210];

            % Create DirectoryOutlineLabel
            app.DirectoryOutlineLabel = uilabel(app.UpdateRightPanel);
            app.DirectoryOutlineLabel.Position = [20 228 99 22];
            app.DirectoryOutlineLabel.Text = 'Directory Outline:';

            % Show the figure after all components are created
            app.UpdateUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Update(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UpdateUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UpdateUIFigure)
        end
    end
end