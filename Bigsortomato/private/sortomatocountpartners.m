function sortomatocountpartners(~, ~, hSortomatoBase)
    % SORTOMATOCOUNTPARTNERS Count the number of interacting surfaces
    %   Detailed explanation goes here
    %
    %  ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %  license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Check for an already-running GUI.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');
    
    if ~isempty(guiChildren)
        guiCountPartners = findobj(guiChildren, 'Tag', 'guiCountPartners');
        
        if ~isempty(guiCountPartners)
            figure(guiCountPartners)
            return
        end % if
    end % if
    
    %% Get the Surpass Surfaces.
    xImarisApp = getappdata(hSortomatoBase, 'xImarisApp');
    surpassSurfaces = xtgetsporfaces(xImarisApp, 'Surfaces');

    % If the scene has no Surfaces, return.
    if isempty(surpassSurfaces)
        return
    end % if
    
    %% Get the data set geometry.
    xMin = xImarisApp.GetDataSet.GetExtendMinX;
    zMin = xImarisApp.GetDataSet.GetExtendMinZ;

    xMax = xImarisApp.GetDataSet.GetExtendMaxX;
    zMax = xImarisApp.GetDataSet.GetExtendMaxZ;

    xSize = xImarisApp.GetDataSet.GetSizeX;
    zSize = xImarisApp.GetDataSet.GetSizeZ;

    %% Calculate the lateral and axial sampling resolution.
    rUnit = (xMax - xMin)/xSize;
    zUnit = (zMax - zMin)/zSize;

    % Use the sampling resolution to calculate a default gap cutoff to feed
    % into inputdlg.
    gapDefault = num2str(min([rUnit, zUnit]));

    %% Set the figure and font colors.
    if all(get(hSortomatoBase, 'Color') == [0 0 0])
        bColor = 'k';
        fColor = 'w';

    else
        bColor = 'w';
        fColor = 'k';
        
    end % if
    
    %% Create a GUI to select surfaces and enter a gap parameter.
    sortomatoPos = get(hSortomatoBase, 'Position');
    
    guiWidth = 230;
    guiHeight = 233;
    guiPos = [...
        sortomatoPos(1) + sortomatoPos(3)/2 - guiWidth/2, ...
        sortomatoPos(2) + sortomatoPos(4) - guiHeight - 25, ...
        guiWidth, ...
        guiHeight];
    
    guiCountPartners = figure(...
        'CloseRequestFcn', {@closerequestfcn, hSortomatoBase}, ...
        'Color', bColor, ...
        'MenuBar', 'None', ...
        'Name', 'Interaction counting', ...
        'NumberTitle', 'Off', ...
        'Position', guiPos, ...
        'Resize', 'Off', ...
        'Tag', 'guiCountPartners');
        
    % Create the Surface selection popup menus.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiCountPartners, ...
        'Position', [10 186 100 24], ...
        'String', 'Surfaces', ...
        'Style', 'text', ...
        'Tag', 'textSurfaces')
    
    popupSurfaces = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiCountPartners, ...
        'Position', [120 190 100 24], ...
        'Style', 'popupmenu', ...
        'String', {surpassSurfaces.Name}, ...
        'Tag', 'popupSurfaces', ...
        'TooltipString', 'Select surfaces for counting', ...
        'Value', 1);
        
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiCountPartners, ...
        'Position', [10 136 100 24], ...
        'String', 'Partners', ...
        'Style', 'text', ...
        'Tag', 'textPartners')
    
    popupPartners = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiCountPartners, ...
        'Parent', guiCountPartners, ...
        'Position', [120 140 100 24], ...
        'String', {surpassSurfaces.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupPartners', ...
        'TooltipString', 'Select partner surfaces', ...
        'Value', 1);
        
    % Create the gap parameter edit box.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiCountPartners, ...
        'Position', [10 88 120 24], ...
        'String', 'Gap allowance', ...
        'Style', 'text', ...
        'Tag', 'textGapValue')
    
    editGapValue = mycontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiCountPartners, ...
        'Position', [150 90 70 24], ...
        'String', gapDefault, ...
        'Style', 'edit', ...
        'Tag', 'editGapValue', ...
        'TooltipString', 'Enter a distance allowance (in microns) for interactions');
    set(editGapValue.Handle, 'Callback', {@editvalidationcallback, editGapValue})    
    
    % Create the calculate button.
    uicontrol(...
        'Background', bColor, ...
        'Callback', {@pushcount}, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiCountPartners, ...
        'Position', [130 40 90 24], ...
        'String', 'Count', ...
        'Style', 'pushbutton', ...
        'Tag', 'pushCount', ...
        'TooltipString', 'Count interactions')
    
    %% Setup the status bar.
    hStatus = statusbar(guiCountPartners, '');
    hStatus.CornerGrip.setVisible(false)
    
    hStatus.ProgressBar.setForeground(java.awt.Color.black)
    hStatus.ProgressBar.setString('')
    hStatus.ProgressBar.setStringPainted(true)
    
    %% Add the GUI to the base's GUI children.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');
    guiChildren = [guiChildren; guiCountPartners];
    setappdata(hSortomatoBase, 'guiChildren', guiChildren)
    
    %% Nested function to perform interaction counting
    function pushcount(varargin)
        % Perform surface interaction counting
        %
        %
        
        %% Get the Surfaces object.
        countSurfacesIdx = get(popupSurfaces, 'Value');
        countSurfaces = surpassSurfaces(countSurfacesIdx).ImarisObject;

        %% Get the partner Surfaces object.
        partnerSurfacesIdx = get(popupPartners, 'Value');
        partnerSurfaces = surpassSurfaces(partnerSurfacesIdx).ImarisObject;
        
        %% Get the gap parameter.
        gapDistance = str2double(get(editGapValue.Handle, 'String'));
                
        %% Get the surfaces track information.
        countSurfaceCount = countSurfaces.GetNumberOfSurfaces;
        countEdges = countSurfaces.GetTrackEdges;
        countTrackIds = countSurfaces.GetTrackIds;

        %% Setup the progress bar.
        hStatus.setText('Getting surfaces');
        hStatus.ProgressBar.setMaximum(countSurfaceCount)
        hStatus.ProgressBar.setVisible(true)

        %% Collect the surface data into a struct.
        countStruct(1:countSurfaceCount) = struct(...
            'Partners', 0, ...
            'Time', [], ...
            'TrackId', [], ...
            'Vertices', []);

        for s = 1:countSurfaceCount
            % Find the current surface's entries in the edge list.
            [edgesRowID, ~] = find(countEdges == s - 1, 1, 'first');

            % Get the parent (track) IDs from the first edge entry (if they exist,
            % 2nd entries in the edges array will be identical).
            countStruct(s).TrackId = countTrackIds(edgesRowID);

            % Get the track time indices.
            countStruct(s).Time = countSurfaces.GetTimeIndex(s - 1);
            
            % Get the vertices.
            countStruct(s).Vertices = countSurfaces.GetVertices(s - 1);

            % Update the progress bar.
            hStatus.ProgressBar.setValue(s)
        end % for s

        %% Get the partner Surfaces.
        % Get the binding partner surfaces. If we are searching the surfaces for
        % homotypic interactions, we can just alias the surface to save the memory
        % (we don't modify the surface data structure(s), just read from them).
        if countSurfacesIdx == partnerSurfacesIdx
            partnerStruct = countStruct;

        else
            % Get the tracked surfaces object information.
            partnerSurfaceCount = partnerSurfaces.GetNumberOfSurfaces;
            partnerTrackIds = partnerSurfaces.GetTrackIds;
            partnerEdges = partnerSurfaces.GetTrackEdges;

            % Update the progress bar.
            hStatus.setText('Getting partner surfaces')
            hStatus.ProgressBar.setMaximum(partnerSurfaceCount)

            % Pre-allocate a structure to hold the tracked surface data.
            partnerStruct(1:partnerSurfaceCount) = struct('Time', [], ...
                'Vertices', [], 'TrackId', []);

            % Now get the track data.
            for s = 1:partnerSurfaceCount
                % Find the current surface's entries in the edge list.
                [edgesRowID, ~] = find(partnerEdges == s - 1, 1, 'first');

                % Get the parent (track) IDs from the first edge entry.
                partnerStruct(s).TrackId = partnerTrackIds(edgesRowID);

                % Get the track time indices.
                partnerStruct(s).Time = partnerSurfaces.GetTimeIndex(s - 1);
                
                % Get the vertices.
                partnerStruct(s).Vertices = partnerSurfaces.GetVertices(s - 1);

                % Update the progress bar.
                hStatus.ProgressBar.setValue(s)
            end % for s

        end % if

        %% For each surface, count the number of target surfaces it touches.
        % Update the progress bar.
        hStatus.setText('Searching for interactions')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setMaximum(countSurfaceCount), ...

        for s = 1:length(countStruct)
            % Find target surfaces present at the current time point.
            partnerIdxs = find([partnerStruct(:).Time] == countStruct(s).Time);
            
            % If we are looking for partners in the same Surfaces,
            % exclude the current surface.
            if countSurfacesIdx == partnerSurfacesIdx
                selfSurfaceIdx = find([countStruct(:).TrackId] == countStruct(s).TrackId);
                targetSelfIdx = ismember(partnerIdxs, selfSurfaceIdx);
                partnerIdxs(targetSelfIdx) = [];
            end

            % Get the surface's Delaunay triangulation and determine the bounding
            % box.
            sortDelaunay = delaunayTriangulation(...
                double(unique(countStruct(s).Vertices, 'Rows')));
            bBoxMin = min(sortDelaunay.Points, [], 1) - (gapDistance + eps('single'));
            bBoxMax = max(sortDelaunay.Points, [], 1) + (gapDistance + eps('single'));

            % At each time point, find objects that come within the cutoff
            % distance.
            for p = 1:length(partnerIdxs)        
                %% Check the nearby targets for encounters with the surface.
                % Get the potential binding partner's vertices.
                partnerVertices = double(partnerStruct(partnerIdxs(p)).Vertices);

                % Find the vertices greater than the bounding box min.
                gtCoords = bsxfun(@ge, partnerVertices, bBoxMin);
                gtVertices = sum(gtCoords, 2) == 3;

                % Find the vertices less than the bounding box max.
                ltCoords = bsxfun(@le, partnerVertices, bBoxMax);
                ltVertices = sum(ltCoords, 2) == 3;

                % Find the vertices that fall within the bounding box.
                bBoxVertices = gtVertices & ltVertices;

                % Mask the vertices to include only those that are within
                % the bounding box.
                testVertices = partnerVertices(bBoxVertices, :);

                % If there are vertices within the bounding box, we search for
                % encounters.
                if ~isempty(testVertices)
                    % Check for target vertices residing within the
                    % surface.
                    enclosingSimplex = pointLocation(sortDelaunay, testVertices);
                    enclosedVertexIdxs = ~isnan(enclosingSimplex);
                    enclosedVerticesCount = sum(enclosedVertexIdxs);

                    % Calculate the distance to the nearest point in the
                    % surface to sort.
                    [~, nearDistances] = nearestNeighbor(sortDelaunay, ...
                        testVertices(~enclosedVertexIdxs, :));

                    % Determine if any points get within the cutoff
                    % distance.
                    partnerFound = (sum(nearDistances <= gapDistance) + ...
                        enclosedVerticesCount) > 0;

                    % If the current target is close enough that we consider it
                    % interacting, record its ID in the interaction record.
                    if partnerFound
                        % Record the interaction in the currrent surfaces
                        countStruct(s).Partners = countStruct(s).Partners + 1;
                    end % if partnerFound
                end % if
            end % for t

            % Update the progress bar.
            hStatus.ProgressBar.setValue(s)
        end % for s

        %% Get the Surfaces time and contacts lists.
        countIdxs = 0:countSurfaceCount - 1;
        countTimes = [countStruct(:).Time];
        countContacts = [countStruct(:).Partners];

        %% Transfer the surface interaction counts to Imaris.
        % Update the status bar and setup the progress bar.
        hStatus.setText('Transferring interaction stats')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setMaximum(2)

        % Create the stat name list.
        contactNames = repmat({['Contacts with ' char(partnerSurfaces.GetName)]}, ...
            [countSurfaceCount, 1]);

        % Create the unit list.
        contactUnits = repmat({'Contacts'}, [countSurfaceCount, 1]); 

        % Assemble the factors cell array.
        contactFactors = cell(3, countSurfaceCount);

        % Set the Category to Surfaces.
        contactFactors(1, :) = repmat({'Surface'}, [countSurfaceCount, 1]);

        % Set the Collection to an empty string.
        contactFactors(2, :) = repmat({''}, [countSurfaceCount, 1]);

        % Set the Time in the Factors.
        contactFactors(3, :) = num2cell(countTimes + 1);

        % Convert the time points to strings.
        contactFactors(3, :) = cellfun(@num2str, contactFactors(3, :), ...
            'UniformOutput', 0);

        % Create the factor names.
        contactFactorNames = {'Category'; 'Collection'; 'Time'};

        % Send the stats to Imaris.
        countSurfaces.AddStatistics(contactNames, countContacts, contactUnits, ...
            contactFactors, contactFactorNames, countIdxs)

        % Update the progress bar.
        hStatus.ProgressBar.setValue(1)

        %% Count the track contacts.
        countSurfaceParents = [countStruct(:).TrackId];
        
        if ~isempty(countSurfaceParents)
            countParentLabels = unique(countSurfaceParents);
            countTrackCount = length(countParentLabels);

            %% Count the total interactions for the tracks.
            sortTrackContactSums = zeros(size(unique(countTrackIds)));
            for s = 1:length(countParentLabels)
                sortTrackContactSums(s) = sum(countContacts(...
                    countSurfaceParents == countParentLabels(s)));
            end % for s

            %% Transfer the track total interactions to Imaris.
            % Create the track stat name list.
            contactTrackNames = repmat({['Track Contacts with ' char(partnerSurfaces.GetName)]}, ...
                [countTrackCount, 1]);

            % Create the unit list.
            contactTrackUnits = repmat({'Contacts'}, [countTrackCount, 1]); 

            % Assemble the factors cell array.
            contactTrackFactors = cell(3, countTrackCount);

            % Set the Category to Tracks.
            contactTrackFactors(1, :) = repmat({'Track'}, [countTrackCount, 1]);

            % Set the Collection to any empty string.
            contactTrackFactors(2, :) = repmat({''}, [countTrackCount, 1]);

            % Set the Time to an empty string.
            contactTrackFactors(3, :) = repmat({''}, [countTrackCount, 1]);

            % Send the stats to Imaris.
            countSurfaces.AddStatistics(contactTrackNames, sortTrackContactSums, ...
                contactTrackUnits, contactTrackFactors, contactFactorNames, countParentLabels')

            % Update the progress bar.
            hStatus.ProgressBar.setValue(2)
        end % if

        %% Reset the status bar.
        hStatus.setText('')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setVisible(false)
    end % pushcount    
end % sortomatocountpartners


%% Callback function to validate editbox changes
function editvalidationcallback(hObject, ~, hObjectContainer)
    % EDITVALIDATIONCALLBACK Verify a string can convert to numeric
    %
    %

    %% Update the editbox value if the input is numeric.
    newValue = str2double(get(hObject, 'String'));

    if isnan(newValue)
        set(hObject, 'String', hObjectContainer.OldString)

    else
        set(hObject, 'String', newValue)
        hObjectContainer.OldString = newValue;

    end % if
end % editvalidationcallback


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