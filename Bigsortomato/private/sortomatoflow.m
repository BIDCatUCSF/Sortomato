function sortomatoflow(~, ~, guiSortomato)
    % SORTOMATOFLOW Calculate directional movement toward a point
    %   Detailed explanation goes here
    %
    %  ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %  license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Check for an already-running GUI.
    guiChildren = getappdata(guiSortomato, 'guiChildren');
    
    if ~isempty(guiChildren)
        guiFlow = findobj(guiChildren, 'Tag', 'guiFlow');
        
        if ~isempty(guiFlow)
            figure(guiFlow)
            return
        end % if
    end % if
    
    %% Get the Surpass Spots and Surfaces.
    xImarisApp = getappdata(guiSortomato, 'xImarisApp');
    surpassObjects = xtgetsporfaces(xImarisApp, 'Both');

    % If the scene has no Spots or Surfaces, return.
    if isempty(surpassObjects)
        return
    end % if
    
    %% Get the data channels.
    xDataSet = xImarisApp.GetDataSet;
    
    if isempty(xDataSet)
        return
    end % if
    
    imarisChannels = cell(xDataSet.GetSizeC, 1);
    for c = 1:xDataSet.GetSizeC
        channelString = char(xDataSet.GetChannelName(c - 1));
        if strcmp(channelString, '(name not specified)')
            imarisChannels{c} = ['Channel ' num2str(c)];
            
        else
            imarisChannels{c} = char(xDataSet.GetChannelName(c - 1));
            
        end % if
    end % for c
    
    %% Calculate a default flow target (the center of the scene).
    xDataSet = xImarisApp.GetDataSet;
    imageCenter = [...
        xDataSet.GetExtendMaxX - xDataSet.GetExtendMinX, ...
        xDataSet.GetExtendMaxY - xDataSet.GetExtendMinY, ...
        xDataSet.GetExtendMaxZ - xDataSet.GetExtendMinZ]/2;
    
    %% Set the figure and font colors.
    if all(get(guiSortomato, 'Color') == [0 0 0])
        bColor = 'k';
        fColor = 'w';

    else
        bColor = 'w';
        fColor = 'k';
        
    end % if
    
    %% Create a GUI to select an object and enter the flow target coordinates.
    sortomatoPos = get(guiSortomato, 'Position');
    
    guiWidth = 230;
    guiHeight = 276;
    guiPos = [...
        sortomatoPos(1) + sortomatoPos(3)/2 - guiWidth/2, ...
        sortomatoPos(2) + sortomatoPos(4) - guiHeight - 25, ...
        guiWidth, ...
        guiHeight];
    
    guiFlow = figure(...
        'CloseRequestFcn', {@closerequestfcn, guiSortomato}, ...
        'Color', bColor, ...
        'MenuBar', 'None', ...
        'Name', 'Flow calculation', ...
        'NumberTitle', 'Off', ...
        'Position', guiPos, ...
        'Resize', 'Off', ...
        'Tag', 'guiFlow');
    
    % Create the object selection popup menu.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiFlow, ...
        'Position', [10 229 108 24], ...
        'String', 'Objects', ...
        'Style', 'text', ...
        'Tag', 'textObjects');
    
    popupObjects = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiFlow, ...
        'Position', [120 233 100 24], ...
        'String', {surpassObjects.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupObjects', ...
        'TooltipString', 'Select object for flow calculation', ...
        'Value', 1);
        
    % Create the mask channel selection popup menu.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiFlow, ...
        'Position', [10 179 100 24], ...
        'String', 'Mask Channel', ...
        'Style', 'text', ...
        'Tag', 'textMask');
    
    popupMask = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiFlow, ...
        'Position', [120 183 100 24], ...
        'String', [{'None'}; imarisChannels], ...
        'Style', 'popupmenu', ...
        'Tag', 'popupMask', ...
        'TooltipString', 'Optional: Select cell mask channel for edge flow calculation', ...
        'Value', 1);
        
    % Create the flow target edit boxes.
    panelFlowCoords = uipanel(...
        'BackgroundColor', bColor, ...
        'BorderType', 'Line', ...
        'FontSize', 12, ...
        'ForegroundColor', fColor, ...
        'HighlightColor', fColor, ...
        'Parent', guiFlow, ...
        'Position', [10 85 210 72]./[guiPos(3) guiPos(4) guiPos(3) guiPos(4)], ...
        'Tag', 'groupFlowCoords', ...
        'Title', 'Flow target', ...
        'TitlePosition', 'Centertop', ...
        'Units', 'Pixels');
    uistack(panelFlowCoords, 'bottom')
    
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Position', [10 29 50 20], ...
        'Parent', panelFlowCoords, ...
        'String', 'X', ...
        'Style', 'text', ...
        'Tag', 'textXValue');
    
    editXValue = mycontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Parent', panelFlowCoords, ...
        'Position', [10 9 50 20], ...
        'String', imageCenter(1), ...
        'Style', 'edit', ...
        'Tag', 'editXValue', ...
        'TooltipString', 'Enter flow target x-coordinate');
    set(editXValue.Handle, 'Callback', {@editvalidationcallback, editXValue})    
    
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Position', [80 29 50 20], ...
        'Parent', panelFlowCoords, ...
        'String', 'Y', ...
        'Style', 'text', ...
        'Tag', 'textYValue');
    
    editYValue = mycontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Parent', panelFlowCoords, ...
        'Position', [80 9 50 20], ...
        'String', imageCenter(2), ...
        'Style', 'edit', ...
        'Tag', 'editYValue', ...
        'TooltipString', 'Enter flow target y-coordinate');
    set(editYValue.Handle, 'Callback', {@editvalidationcallback, editYValue})    
    
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Position', [150 29 50 20], ...
        'Parent', panelFlowCoords, ...
        'String', 'Z', ...
        'Style', 'text', ...
        'Tag', 'textZValue');
    
    editZValue = mycontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Parent', panelFlowCoords, ...
        'Position', [150 9 50 20], ...
        'String', imageCenter(3), ...
        'Style', 'edit', ...
        'Tag', 'editZValue', ...
        'TooltipString', 'Enter flow target z-coordinate');
    set(editZValue.Handle, 'Callback', {@editvalidationcallback, editZValue})    
    
    % Create the calculate button.
    uicontrol(...
        'Background', bColor, ...
        'Callback', {@pushcalc}, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiFlow, ...
        'Position', [130 40 90 24], ...
        'String', 'Calculate', ...
        'Style', 'pushbutton', ...
        'Tag', 'pushCalc', ...
        'TooltipString', 'Calculate flows');
    
    %% Setup the status bar.
    hStatus = statusbar(guiFlow, '');
    hStatus.CornerGrip.setVisible(false)
    
    hStatus.ProgressBar.setForeground(java.awt.Color.black)
    hStatus.ProgressBar.setString('')
    hStatus.ProgressBar.setStringPainted(true)
    
    %% Add the GUI to the base's GUI children.
    guiChildren = getappdata(guiSortomato, 'guiChildren');
    guiChildren = [guiChildren; guiFlow];
    setappdata(guiSortomato, 'guiChildren', guiChildren)
    
    %% Nested function to perform flow calculation
    function pushcalc(varargin)
        % Calculate the flow
        %
        %
        
        %% Get the Surpass object.
        flowObjectIdx = get(popupObjects, 'Value');
        xObject = surpassObjects(flowObjectIdx).ImarisObject;

        %% Convert the flow coordinate edit box data to numeric values.
        xc = str2double(get(editXValue.Handle, 'String'));
        yc = str2double(get(editYValue.Handle, 'String'));
        zc = str2double(get(editZValue.Handle, 'String'));
                
        %% Setup the status bar.
        hStatus.setText('Calculating flows');

        %% Get the Surpass object data.
        if xImarisApp.GetFactory.IsSpots(xObject)
            % Cast the object to Spots.
            xObject = xImarisApp.GetFactory.ToSpots(xObject);

            % Get the spot positions.
            objectPos = xObject.GetPositionsXYZ;

            % Get the spot times.
            objectTimes = xObject.GetIndicesT;

        else
            % Cast the object to Surfaces.
            xObject = xImarisApp.GetFactory.ToSurfaces(xObject);

            % Get the number of surfaces.
            surfaceCount = xObject.GetNumberOfSurfaces;

            % Get the surface positions and times.
            objectPos = zeros(surfaceCount, 3);
            objectTimes = zeros(surfaceCount, 1);
            for s = 1:surfaceCount
                objectPos(s, :) = xObject.GetCenterOfMass(s - 1);
                objectTimes(s) = xObject.GetTimeIndex(s - 1);
            end % s

        end % if

        %% Create a list of object indexes and get the track information.
        % Create the spot indexes (just a 0-based index).
        objectIdxs = transpose(0:size(objectPos, 1) - 1);

        % Get the track information.
        trackIDs = xObject.GetTrackIds;
        trackEdges = xObject.GetTrackEdges;
        trackLabels = unique(trackIDs);

        %% If there are no tracks, return.
        if isempty(trackEdges)
            hStatus.setText(['No track data found'])
            return
        end % if
        
        %% If a cell mask was provided, get the mask and allocate arrays for the edge flow.
        if get(popupMask, 'Value') > 1
            % Get the pixel size.
            pixelSize = (xDataSet.GetExtendMaxX - xDataSet.GetExtendMinX)/xDataSet.GetSizeX;
            
            % Get the mask channel index.
            maskChannelIdx = get(popupMask, 'Value') - 2;
            
            % Allocate an array for the mask.
            maskTraces = cell(1, xDataSet.GetSizeT);
            
            % Read the mask and create traces of the edge.
            switch char(xDataSet.GetType)
                
                case 'eTypeUInt8'
                    for t = 1:xDataSet.GetSizeT
                        % Get the slice mask.
                        tMask = logical(xDataSet.GetDataSliceBytes(...
                            0, maskChannelIdx, t - 1));

                        % Identify the cell region and mask.
                        cellProps = regionprops(tMask, 'Area', 'PixelIdxList');
                        cellRgnIdx = [cellProps.Area] == max([cellProps.Area]);
                        tCellMask = false(size(tMask));
                        tCellMask(cellProps(cellRgnIdx).PixelIdxList) = 1;

                        % Trace the cell mask.
                        [rStart, cStart] = find(tCellMask, 1, 'first');
                        tTrace = bwtraceboundary(tCellMask, [rStart, cStart], 'S');

                        % Convert the trace to Imaris xy coordinates.
                        maskTraces{t} = transpose(pixelSize*(tTrace - 1));
                    end % for t                    

                case 'eTypeUInt16'
                    for t = 1:xDataSet.GetSizeT
                        % Get the slice mask.
                        tMask = logical(xDataSet.GetDataSliceShorts(...
                            0, maskChannelIdx, t - 1));

                        % Identify the cell region and mask.
                        cellProps = regionprops(tMask, 'Area', 'PixelIdxList');
                        cellRgnIdx = [cellProps.Area] == max([cellProps.Area]);
                        tCellMask = false(size(tMask));
                        tCellMask(cellProps(cellRgnIdx).PixelIdxList) = 1;

                        % Trace the cell mask.
                        [rStart, cStart] = find(tCellMask, 1, 'first');
                        tTrace = bwtraceboundary(tCellMask, [rStart, cStart], 'S');

                        % Convert the trace to Imaris xy coordinates.
                        maskTraces{t} = transpose(pixelSize*(tTrace - 1));
                    end % for t                    

                case 'eTypeFloat'
                    for t = 1:xDataSet.GetSizeT
                        % Get the slice mask.
                        tMask = logical(xDataSet.GetDataSliceFloats(...
                            0, maskChannelIdx - 1, t - 1));

                        % Identify the cell region and mask.
                        cellProps = regionprops(tMask, 'Area', 'PixelIdxList');
                        cellRgnIdx = [cellProps.Area] == max([cellProps.Area]);
                        tCellMask = false(size(tMask));
                        tCellMask(cellProps(cellRgnIdx).PixelIdxList) = 1;

                        % Trace the cell mask.
                        [rStart, cStart] = find(tCellMask, 1, 'first');
                        tTrace = bwtraceboundary(tCellMask, [rStart, cStart], 'S');

                        % Convert the trace to Imaris xy coordinates.
                        maskTraces{t} = transpose(pixelSize*(tTrace - 1));
                    end % for t                    

            end % switch
            
            % Allocate a vector for the edge flow data.
            edgeRadPos = zeros(size(objectIdxs), 'single');
            edgeInstantFlows = zeros(size(objectIdxs), 'single');
            edgeFlows = zeros(size(objectIdxs), 'single');
        end % if
        
        %% Calculate the flows.
        % Allocate a vector for the radial position and flow data.
        objectRadPos = zeros(size(objectIdxs), 'single');
        objectInstantFlows = zeros(size(objectIdxs), 'single');
        objectFlows = zeros(size(objectIdxs), 'single');
        
        % Allocate a vector for the track centralization.
        trackCentralizations = zeros(size(trackLabels), 'single');
        
        % Setup the progress bar.
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setMaximum(length(trackLabels))
        hStatus.ProgressBar.setVisible(true)

        % Calculate the flows for all the tracks.
        for r = 1:length(trackLabels)
            % Get indices for the track.
            rEdges = trackEdges(trackIDs == trackLabels(r), :);
            rIDs = unique(rEdges);

            % Get the track positions.
            rPos = objectPos(rIDs + 1, :);

            % Calculate the distances to the center:
            R = bsxfun(@minus, [xc, yc, zc], rPos);
            rDist = sqrt(sum(R.^2, 2));
            objectRadPos(rIDs + 1) = rDist;

            % Calculate the flows:
            
            % Calculate the vectors from the object positions to the centroid.
            % Calculate the track movement vectors.
            rVectors = diff(rPos);

            % Calculate the object-to-center vectors.
            S = bsxfun(@minus, [xc, yc, zc], rPos(1:end - 1, :));

            % Calculate the projections on to the vector to the centroid (the
            % radial movement toward the centroid) and the cumulative flow toward
            % the centroid.
            rDisp = dot(rVectors, S, 2)./sqrt(sum(S.^2, 2));
            rFlow = [0; cumsum(rDisp)];

            % Add the flows to the vectors at the track spot indices.
            objectInstantFlows(rIDs(2:end) + 1) = rDisp;
            objectFlows(rIDs + 1) = rFlow;
            
            % If a cell mask channel was selected calculate the edge flow.
            if get(popupMask, 'Value') > 1
                % Get the time indexes for the track.
                rTimeIdxs = objectTimes(rIDs + 1) + 1;
                
                % Allocate an array to record the intersections.
                rEdgePos = zeros(size(rPos), 'single');
                rEdgePos(:, 3) = rPos(:, 3);
                
                % Calculate the location on the edge beyond the spot.
                for p = 1:size(rPos, 1)
                    % Convert the spot coordinates to target-centered
                    % spherical coordinates.
                    [tp, rp] = cart2pol(...
                        rPos(r, 1) - xc, rPos(r, 2) - yc);
                    
                    % Generate the line through the spot and convert to
                    % Cartesian coordinates.
                    [xl, yl] = pol2cart(...
                        tp, linspace(0, rp + xDataSet.GetSizeX*pixelSize, 64)');
                    lineCoords = bsxfun(@plus, [xl, yl], [xc, yc]);
                    
                    % Calculate the intersection with the edge.
                    pIntersections = InterX(maskTraces{rTimeIdxs(p)}, ...
                        transpose(lineCoords(:, 1:2)));
                    rEdgePos(p, 1:2) = pIntersections(:, 1);
                end % for p
                
                % Calculate the distances to the center:
                R = bsxfun(@minus, [xc, yc, zc], rPos);
                edgeRadPos(rIDs + 1) = sqrt(sum(R.^2, 2));
                
                % Calculate the edge-to-center vectors.
                S = bsxfun(@minus, [xc, yc, zc], rEdgePos(1:end - 1, :));
                
                % Calculate the projections on to the vector to the centroid (the
                % radial movement toward the centroid) and the cumulative flow toward
                % the centroid.
                rEdgeVectors = diff(rEdgePos);
                rEdgeDisp = dot(rEdgeVectors, S, 2)./sqrt(sum(S.^2, 2));
                rEdgeFlow = [0; cumsum(rDisp)];

                % Add the flows to the vectors at the track spot indices.
                edgeInstantFlows(rIDs(2:end) + 1) = rEdgeDisp;
                edgeFlows(rIDs + 1) = rEdgeFlow;
            end % if
            
            % If the particle flows inward, calculate its centralization.
            if find(max(rDist)) ~= length(rDist)
                trackCentralizations(r) = max(rDist) - ...
                    min(rDist(find(max(rDist)) + 1:end));
            end % if

            % Update the waitbar.
            hStatus.ProgressBar.setValue(r)
        end % for r

        %% Transfer the radial displacements to Imaris.
        % Update the status bar and progress bar.
        hStatus.setText('Transferring flow data')
        hStatus.ProgressBar.setValue(0)
        
        if get(popupMask, 'Value') > 1
            hStatus.ProgressBar.setMaximum(7)
            
        else
            hStatus.ProgressBar.setMaximum(4)
            
        end % if
        
        % Create the stat name list.
        radPosNames = repmat({'Radial distance'}, size(objectIdxs));

        % Create the unit list.
        imarisUnits = char(xImarisApp.GetDataSet.GetUnit);
        if isempty(imarisUnits)
            imarisUnits = 'um';
        end % if
        flowUnits = repmat({imarisUnits}, size(objectIdxs)); 

        % Assemble the factors cell array.
        flowFactors = cell(3, length(objectIdxs));

        % Set the Category.
        if xImarisApp.GetFactory.IsSpots(xObject)
            flowFactors(1, :) = repmat({'Spot'}, size(objectIdxs));

        else
            flowFactors(1, :) = repmat({'Surface'}, size(objectIdxs));

        end % if

        % Set the Collection to an empty string.
        flowFactors(2, :) = repmat({''}, size(objectIdxs));

        % Set the Time factors.
        flowFactors(3, :) = num2cell(objectTimes + 1);

        % Convert the time points to strings...
        flowFactors(3, :) = cellfun(@num2str, flowFactors(3, :), ...
            'UniformOutput', 0);

        % Create the factor names.
        factorNames = {'Category'; 'Collection'; 'Time'};

        % Send the radial displacements to Imaris.
        xObject.AddStatistics(radPosNames, objectRadPos, flowUnits, flowFactors, ...
            factorNames, objectIdxs)

        % Update the progress bar.
        hStatus.ProgressBar.setValue(1)

        %% Transfer the instantaneous flows to Imaris.
        % Create the stat name list.
        instantFlowNames = repmat({'Flow rate'}, size(objectIdxs));
        
        % Create the unit list.
        flowRateUnits = repmat({[imarisUnits '/s']}, size(objectIdxs)); 
        
        % Send the flow stats to Imaris.
        xObject.AddStatistics(instantFlowNames, objectInstantFlows, flowRateUnits, ...
            flowFactors, factorNames, objectIdxs)

        % Update the progress bar.
        hStatus.ProgressBar.setValue(2)
        
        %% Transfer the flow stats to Imaris.
        % Create the stat name list.
        flowNames = repmat({'Flow'}, size(objectIdxs));

        % Send the flow stats to Imaris.
        xObject.AddStatistics(flowNames, objectFlows, flowUnits, flowFactors, ...
            factorNames, objectIdxs)

        % Update the progress bar.
        hStatus.ProgressBar.setValue(3)

        %% Transfer the centralizations to Imaris.
        % Create the track stat name list.
        centralizationNames = repmat({'Track centralization'}, ...
            size(trackLabels));

        % Create the track unit list.
        centralizationUnits = repmat({imarisUnits}, size(trackLabels));

        % Assemble the factors cell array.
        centralizationFactors = cell(3, length(trackLabels));

        % Set the Category to Tracks.
        centralizationFactors(1, :) = repmat({'Track'}, size(trackLabels));

        % Set the Collection to any empty string.
        centralizationFactors(2, :) = repmat({''}, size(trackLabels));

        % Set the Time to an empty string.
        centralizationFactors(3, :) = repmat({''}, size(trackLabels));

        % Send the centralization stats to Imaris.
        xObject.AddStatistics(centralizationNames, trackCentralizations, ...
            centralizationUnits, centralizationFactors, factorNames, trackLabels)
        
        hStatus.ProgressBar.setValue(4)
        
        %% If the edge data was calculated, transfer the statistics for the edge flow.
        if get(popupMask, 'Value') > 1
            % Create the stat name list.
            edgeRadPosNames = repmat({'Edge radial distance'}, size(objectIdxs));
            
            % Send the edge radial displacements to Imaris.
            xObject.AddStatistics(edgeRadPosNames, edgeRadPos, flowUnits, flowFactors, ...
                factorNames, objectIdxs)

            % Update the progress bar.
            hStatus.ProgressBar.setValue(5)

            %% Transfer the instantaneous edge flows to Imaris.
            % Create the stat name list.
            instantEdgeFlowNames = repmat({'Edge flow rate'}, size(objectIdxs));

            % Send the flow stats to Imaris.
            xObject.AddStatistics(instantEdgeFlowNames, edgeInstantFlows, flowRateUnits, ...
                flowFactors, factorNames, objectIdxs)

            % Update the progress bar.
            hStatus.ProgressBar.setValue(6)

            %% Transfer the edge flow stats to Imaris.
            % Create the stat name list.
            edgeFlowNames = repmat({'Edge flow'}, size(objectIdxs));

            % Send the flow stats to Imaris.
            xObject.AddStatistics(edgeFlowNames, edgeFlows, flowUnits, flowFactors, ...
                factorNames, objectIdxs)

            % Update the progress bar.
            hStatus.ProgressBar.setValue(7)
        end % if        
        
        %% Reset the status bar.
        hStatus.setText('')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setVisible(false)
    end % pushcalc    
end % sortomatoflow


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