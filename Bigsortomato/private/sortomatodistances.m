function sortomatodistances(~, ~, hSortomatoBase)
    % SORTOMATODISTANCES Calculate minimum distances between objects
    %   Detailed explanation goes here
    %
    %  ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %  license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Check for an already-running GUI.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');
    
    if ~isempty(guiChildren)
        guiDistances = findobj(guiChildren, 'Tag', 'guiDistances');
        
        if ~isempty(guiDistances)
            figure(guiDistances)
            return
        end % if
    end % if
    
    %% Get the Surpass Spots and Surfaces.
    xImarisApp = getappdata(hSortomatoBase, 'xImarisApp');
    surpassObjects = xtgetsporfaces(xImarisApp, 'Both');

    % If the scene has no Spots or Surfaces, return.
    if isempty(surpassObjects)
        return
    end % if
    
    %% Set the figure and font colors.
    if all(get(hSortomatoBase, 'Color') == [0 0 0])
        bColor = 'k';
        fColor = 'w';

    else
        bColor = 'w';
        fColor = 'k';
        
    end % if
    
    %% Create a GUI to select objects to use for the distance calculation.
    sortomatoPos = get(hSortomatoBase, 'Position');
    
    guiWidth = 230;
    guiHeight = 253;
    guiPos = [...
        sortomatoPos(1) + sortomatoPos(3)/2 - guiWidth/2, ...
        sortomatoPos(2) + sortomatoPos(4)/2 - guiHeight/2, ...
        guiWidth, ...
        guiHeight];
    
    guiDistances = figure(...
        'CloseRequestFcn', {@closerequestfcn, hSortomatoBase}, ...
        'Color', bColor, ...
        'MenuBar', 'None', ...
        'Name', 'Distance calculation', ...
        'NumberTitle', 'Off', ...
        'Position', guiPos, ...
        'Resize', 'Off', ...
        'Tag', 'guiDistances');
        
    % Create the object selection popup menus.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiDistances, ...
        'Position', [10 206 108 24], ...
        'String', 'Objects', ...
        'Style', 'text', ...
        'Tag', 'textObjects');
    
    popupObjects = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiDistances, ...
        'Position', [120 210 100 24], ...
        'String', {surpassObjects.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupObjects', ...
        'TooltipString', 'Select objects for distance calculation', ...
        'Value', 1);
        
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiDistances, ...
        'Position', [10 156 108 24], ...
        'String', 'Distance to', ...
        'Style', 'text', ...
        'Tag', 'textPartners');
    
    popupPartners = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiDistances, ...
        'Position', [120 160 100 24], ...
        'String', {surpassObjects.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupPartners', ...
        'TooltipString', 'Select partner objects for distance calculation', ...
        'Value', 1);
    
    % Create a panel to use centroids or vertices for the calculation.
    groupCalcMethod = uibuttongroup(...
        'BackgroundColor', bColor, ...
        'BorderType', 'Line', ...
        'FontSize', 12, ...
        'ForegroundColor', fColor, ...
        'HighlightColor', fColor, ...
        'Parent', guiDistances, ...
        'Position', [10 85 210 50]./[guiPos(3) guiPos(4) guiPos(3) guiPos(4)], ...
        'Title', 'Calculation reference', ...
        'TitlePosition', 'Centertop', ...
        'Tag', 'groupCalcMethod', ...
        'Units', 'Pixels');
    
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Parent', groupCalcMethod, ...
        'Position', [10 8 74 24], ...
        'Tag', 'radioCentroids', ...
        'String', 'Centroids', ...
        'Style', 'radiobutton', ...
        'TooltipString', 'Use centroids');
    
    radioVertices = uicontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Parent', groupCalcMethod, ...
        'Position', [115 8 67 24], ...
        'String', 'Vertices', ...
        'Style', 'radiobutton', ...
        'TooltipString', 'Use nearest vertices');
    
    % If all the objects are Spots, disable vertices calculation.
    if all(strcmp({surpassObjects.Type}, 'Spots'))
        set(radioVertices, 'Enable', 'Off')
    end % if
    
    % Create the calculate button.
    uicontrol(...
        'Background', bColor, ...
        'Callback', {@pushcalc}, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiDistances, ...
        'Position', [130 40 90 24], ...
        'String', 'Calculate', ...
        'Style', 'pushbutton', ...
        'Tag', 'pushCalc', ...
        'TooltipString', 'Calculate distances');
    
    %% Setup the status bar.
    hStatus = statusbar(guiDistances, '');
    hStatus.CornerGrip.setVisible(false)
    
    hStatus.ProgressBar.setForeground(java.awt.Color.black)
    hStatus.ProgressBar.setString('')
    hStatus.ProgressBar.setStringPainted(true)
    
    %% Add the GUI to the base's GUI children.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');
    guiChildren = [guiChildren; guiDistances];
    setappdata(hSortomatoBase, 'guiChildren', guiChildren)
    
    %% Nested function to perform distance calculation
    function pushcalc(varargin)
        % Calculate distances to other objects
        %
        %
        
        %% Get the primary object.
        objectIdx = get(popupObjects, 'Value');
        primaryObject = surpassObjects(objectIdx).ImarisObject;

        %% Get the secondary object.
        partnerIdx = get(popupPartners, 'Value');
        secondaryObject = surpassObjects(partnerIdx).ImarisObject;

        %% Setup the status bar.
        hStatus.setText('Getting data')

        %% Collect the secondary object data based on its type.
        if xImarisApp.GetFactory.IsSpots(secondaryObject)
            % Get the Spots data.
            secondaryPositions = transpose(secondaryObject.GetPositionsXYZ);
            secondaryTimeIdxs = secondaryObject.GetIndicesT;
            
            % Calculate the number of secondary spots.
            secondaryObjectCount = size(secondaryTimeIdxs, 1);
            
            % Distrubute the secondary spots into a struct.
            secondaryStruct(1:secondaryObjectCount) = struct(...
                'ID', num2cell(0:secondaryObjectCount - 1), ...
                'Vertices', num2cell(secondaryPositions, 1), ...
                'Time', num2cell(secondaryTimeIdxs'));
            
        else
            % Get the number of secondary surfaces.
            secondaryObjectCount = secondaryObject.GetNumberOfSurfaces;

            % Allocate a struct for the secondary surfaces.
            secondaryStruct(secondaryObjectCount) = struct(...
                'ID', [], ... % Only needed if we want to return the ID of the nearest object.
                'Vertices', [], ...
                'Time', []);

            % Get the surface data. If the user wanted to calculate
            % distances between centroids, get the center of mass and store
            % it in the Vertices field.
            calcMethod = get(get(groupCalcMethod, 'SelectedObject'), 'String');
            switch calcMethod

                case 'Centroids'
                    for s = 1:secondaryObjectCount
                        secondaryStruct(s).ID = s - 1;
                        secondaryStruct(s).Time = secondaryObject.GetTimeIndex(s - 1);
                        secondaryStruct(s).Vertices = transpose(...
                            secondaryObject.GetCenterOfMass(s - 1));
                    end % for s

                case 'Vertices'
                    for s = 1:secondaryObjectCount
                        secondaryStruct(s).ID = s - 1;
                        secondaryStruct(s).Time = secondaryObject.GetTimeIndex(s - 1);
                        secondaryStruct(s).Vertices = transpose(...
                            secondaryObject.GetVertices(s - 1));
                    end % for s

            end % switch

            % Create a time index list.
            secondaryTimeIdxs = [secondaryStruct.Time];

        end % if

        %% Do the distance calculation based on the search type.
        % Update the status bar.
        hStatus.setText('Calculating distances')
        
        if xImarisApp.GetFactory.IsSpots(primaryObject)
            % Get the positions.
            primaryPositions = transpose(primaryObject.GetPositionsXYZ);

            % Get the time points.
            primaryTimeIdxs = primaryObject.GetIndicesT;

            % Calculate the number of secondary spots.
            primaryObjectCount = size(primaryTimeIdxs, 1);

            % Allocate the variable to record all the primary distances.
            primaryObjectDistance = inf(primaryObjectCount, 1);

            % Update the progress bar.
            hStatus.ProgressBar.setMaximum(primaryObjectCount)
            hStatus.ProgressBar.setVisible(true)

            for p = 1:primaryObjectCount
                % Get the pth primary object position.
                primaryVertices = primaryPositions(:, p);

                % Find the partner objects at the current spot's time point.
                pTimeObjects = find(secondaryTimeIdxs == primaryTimeIdxs(p));

                % If we are searching within the same Surpass object,
                % exclude the current object from the search.
                if objectIdx == partnerIdx
                    pTimeObjects = pTimeObjects(pTimeObjects ~= p);
                end % if
                
                % If there are other objects present, calculate the nearest
                % distance to them.
                if ~isempty(pTimeObjects)
                    % Get the vertices for the objects present at the same time as the
                    % primary object.
                    pTimeVertices = [secondaryStruct(pTimeObjects).Vertices];

                    % Create a vector to record the distances.
                    vDistanceList = inf(size(primaryVertices, 2), 1, 'single');

                    % Calculate the shortest distance between vertices.
                    for v = 1:size(primaryVertices, 2)
                        % Calculate the vectors between the vertices.
                        vertexDifferences = bsxfun(@minus, primaryVertices(:, v), ...
                            pTimeVertices);

                        % Calculate the minimum distance.
                        vDistanceList(v) = min(sqrt(sum(vertexDifferences.^2, 1)));
                    end % v

                    % Find the shortest distance to a vertex in the other object.
                    primaryObjectDistance(p) = min(vDistanceList);
                end % if
                
                % Update the progress bar.
                hStatus.ProgressBar.setValue(p)
            end % for p

        else
            % Get the number of surfaces.
            primaryObjectCount = primaryObject.GetNumberOfSurfaces;

            % Allocate a vector to record all the time indexes (needed when we
            % create the stat arrays for Imaris.
            primaryTimeIdxs = zeros(primaryObjectCount, 1);

            % Allocate the vector to record all the primary distances.
            primaryObjectDistance = inf(primaryObjectCount, 1);

            % Update the progress bar.
            % Update the progress bar.
            hStatus.ProgressBar.setMaximum(primaryObjectCount)
            hStatus.ProgressBar.setVisible(true)

            % Get each surface's vertices and iterate.
            for p = 1:primaryObjectCount
                % Get the pth primary surface vertices.
                primaryVertices = transpose(primaryObject.GetVertices(p - 1));

                % Get the pth primary surface time index.
                primaryTimeIdxs(p) = primaryObject.GetTimeIndex(p - 1);

                % Find the partner objects at the current surface's time point.
                pTimeObjects = find(secondaryTimeIdxs == primaryTimeIdxs(p));

                % If we are searching within the same Surpass object, we need to
                % exclude the current object from the search.
                if objectIdx == partnerIdx
                    pTimeObjects = pTimeObjects(pTimeObjects ~= p);
                end % if

                if ~isempty(pTimeObjects)
                    % Get the vertices for the objects present at the same time as the
                    % primary object.
                    pTimeVertices = [secondaryStruct(pTimeObjects).Vertices];

                    % Create a vector to record the distances.
                    vDistanceList = inf(size(primaryVertices, 2), 1, 'single');

                    % Calculate the shortest distance between vertices.
                    for v = 1:size(primaryVertices, 2)
                        % Calculate the vectors between the vertices.
                        vertexDifferences = bsxfun(@minus, primaryVertices(:, v), ...
                            pTimeVertices);

                        % Calculate the minimum distance.
                        vDistanceList(v) = min(sqrt(sum(vertexDifferences.^2, 1)));
                    end % for v

                    % Find the shortest distance to a vertex in the other object.
                    primaryObjectDistance(p) = min(vDistanceList);

            %%% This code can be modified to find the ID of the closest object. %%%%%%%
            %         
            %         % Allocate a vector to hold the distances to the secondary objects.
            %         psDistances = inf(size(pTimeObjects));
            %         
            %         for s = pTimeObjects
            %             % Get the secondary surface vertices.
            %             secondaryVertices = secondaryStruct(s).Vertices;
            % 
            %             % Create a vector to record the distances.
            %             vDistanceList = inf(size(primaryVertices, 2), 1, 'single');
            % 
            %             % Calculate the distance from all the primary surface
            %             % vertices to the closest secondary vertex.
            %             for v = 1:size(primaryVertices, 2)
            %                 % Calculate the vectors between the vertices.
            %                 vertexDifferences = bsxfun(@minus, primaryVertices(:, v), ...
            %                     secondaryVertices);
            % 
            %                 % Calculate the minimum distance.
            %                 vDistanceList(v) = min(sqrt(sum(vertexDifferences.^2, 2)));
            %             end % v
            %             
            %             psDistances(s) = min([psDistances(s); min(vDistanceList)]);
            %             
            %         end % s
            %         
            %         % Calculate the distance to the closest object.
            %         primaryObjectDistance(p) = min(psDistances);
            % 
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                end % if
                
                % Update the progress bar.
                hStatus.ProgressBar.setValue(p)
            end % for p

        end % if

        %% Transfer the distances statistics to Imaris.
        % Update the status and progress bars.
        hStatus.setText('Transferring distances')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setMaximum(1)

        % Create the distance statistic name list.
        distBaseName = ['Distance to ' char(secondaryObject.GetName) ' ']; % Trailing space is to get Imaris to behave and show the units.
        distNames = repmat({distBaseName}, [primaryObjectCount 1]); 

        % Create the stat unit list.
        imarisUnits = char(xImarisApp.GetDataSet.GetUnit);
        if isempty(imarisUnits)
            imarisUnits = 'um';
        end % if
        distUnits = repmat({imarisUnits}, [primaryObjectCount, 1]); 

        % Assemble the factors cell array.
        distFactors = cell(3, primaryObjectCount);

        % Set the Category.
        if xImarisApp.GetFactory.IsSpots(primaryObject)
            distFactors(1, :) = repmat({'Spot'}, [primaryObjectCount 1]);

        else
            distFactors(1, :) = repmat({'Surface'}, [primaryObjectCount 1]);

        end % if

        % Set the Collection to an empty string.
        distFactors(2, :) = repmat({''}, [primaryObjectCount 1]);

        % Set the Time.
        distFactors(3, :) = num2cell(primaryTimeIdxs + 1);

        % Convert the time points to strings.
        distFactors(3, :) = cellfun(@num2str, distFactors(3, :), ...
            'UniformOutput', 0);

        % Create the factor names.
        factorNames = {'Category', 'Collection', 'Time'};

        % Create the stat IDs.
        distIDs = transpose(0:primaryObjectCount - 1);

        % Send the distance statistics to Imaris.
        primaryObject.AddStatistics(distNames, primaryObjectDistance, distUnits, ...
            distFactors, factorNames, distIDs)
        
        % Update the progress bar.
        hStatus.ProgressBar.setValue(1)
        
        %% Reset the progress and status bars.
        hStatus.setText('')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setVisible(false)
    end % pushcalc    
end % sortomatodistances


function closerequestfcn(hObject, ~, hSortomatoBase)
    % Close sortomato sub-GUIs
    %
    %
    
    %% Remove the GUI's handle from the base's appdata and delete.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');

    guiIdx = guiChildren == hObject;
    guiChildren = guiChildren(~guiIdx);
    setappdata(hSortomatoBase, 'guiChildren', guiChildren)
    delete(hObject);
end % closerequestfcn