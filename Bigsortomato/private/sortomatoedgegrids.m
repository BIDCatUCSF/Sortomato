function sortomatoedgegrids(hObject, ~, hSortomatoBase)
    % SORTOMATOEDGEGRIDS Divide the cell edge into a grid and calculate
    % intensities
    %   Detailed explanation goes here
    %
    %  ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %  license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Check for an already-running GUI.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');
    
    if ~isempty(guiChildren)
        guiEdgeGrids = findobj(guiChildren, 'Tag', 'guiEdgeGrids');
        
        if ~isempty(guiEdgeGrids)
            figure(guiEdgeGrids)
            return
        end % if
    end % if
    
    %% Get the data channels.
    xImarisApp = getappdata(hSortomatoBase, 'xImarisApp');
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
    
    %% Set the figure and font colors.
    if all(get(hSortomatoBase, 'Color') == [0 0 0])
        bColor = 'k';
        fColor = 'w';

    else
        bColor = 'w';
        fColor = 'k';
        
    end % if
    
    %% Create the GUI figure.
    sortomatoPos = get(hSortomatoBase, 'Position');
    
    guiWidth = 230;
    guiHeight = 330;
    guiPos = [...
        sortomatoPos(1) + sortomatoPos(3)/2 - guiWidth/2, ...
        sortomatoPos(2) + sortomatoPos(4) - guiHeight - 25, ...
        guiWidth, ...
        guiHeight];
    
    guiEdgeGrids = figure(...
        'CloseRequestFcn', {@closerequestfcn, hSortomatoBase}, ...
        'Color', bColor, ...
        'MenuBar', 'None', ...
        'Name', 'Edge grid intensity', ...
        'NumberTitle', 'Off', ...
        'Position', guiPos, ...
        'Resize', 'Off', ...
        'Tag', 'guiEdgeGrids');
        
    % Create the refresh button.
    uicontrol(...
        'BackgroundColor', bColor, ...
        'Callback', {@pushchannelrefresh, xDataSet}, ...
        'CData', get(hObject, 'UserData'), ...
        'Parent', guiEdgeGrids, ...
        'Position', [10 284 24 24], ...
        'String', '', ...
        'Style', 'Pushbutton', ...
        'Tag', 'pushRefresh', ...
        'TooltipString', 'Refresh the Imaris channels');
    
    % Create the intensity channel selection popup menu.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiEdgeGrids, ...
        'Position', [48 282 60 24], ...
        'String', 'Channel', ...
        'Style', 'text', ...
        'Tag', 'textChannel');
    
    popupChannel = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiEdgeGrids, ...
        'Position', [120 286 100 24], ...
        'String', imarisChannels, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupChannel', ...
        'TooltipString', 'Select the channel to use for the grid region intensities', ...
        'Value', 1);
        
    % Create the mask channel selection popup menu.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiEdgeGrids, ...
        'Position', [10 232 108 24], ...
        'String', 'Mask channel', ...
        'Style', 'text', ...
        'Tag', 'textMask');
    
    % If there is a channel with mask in the name, pre-select it.
    maskChannelIdxs = ~cellfun(@isempty, ...
        regexp(imarisChannels, 'Mask|mask', 'Start', 'Once'));
    if any(maskChannelIdxs)
        defaultMaskValue = find(maskChannelIdxs, 1, 'first');
        
    else
        defaultMaskValue = 2;
        
    end % if
    
    popupMask = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiEdgeGrids, ...
        'Position', [120 236 100 24], ...
        'String', imarisChannels, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupMask', ...
        'TooltipString', 'Select the mask channel', ...
        'Value', defaultMaskValue);
    
    % Create the target factor group.
    groupGridFactors = uipanel(...
        'BackgroundColor', bColor, ...
        'BorderType', 'Line', ...
        'FontSize', 12, ...
        'ForegroundColor', fColor, ...
        'HighlightColor', fColor, ...
        'Parent', guiEdgeGrids, ...
        'Position', [10 90 210 120]./[guiPos(3) guiPos(4) guiPos(3) guiPos(4)], ...
        'Title', 'Grid settings', ...
        'TitlePosition', 'Centertop', ...
        'Tag', 'groupGridFactors', ...
        'Units', 'Pixels');
    uistack(groupGridFactors, 'bottom')

    % Create the edge depth edit box.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', groupGridFactors, ...
        'Position', [10 77 100 20], ...
        'String', 'Grid depth (um)', ...
        'Style', 'text', ...
        'Tag', 'textGridDepth');
    
    editGridDepth = mycontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Parent', groupGridFactors, ...
        'Position', [150 79 50 20], ...
        'String', 2, ...
        'Style', 'edit', ...
        'Tag', 'editGridDepth', ...
        'TooltipString', 'Enter the grid regions'' thickness');
    set(editGridDepth.Handle, 'Callback', {@editvalidationcallback, editGridDepth, xDataSet})
    
    % Create the region number edit box.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', groupGridFactors, ...
        'Position', [10 42 100 20], ...
        'String', 'Grid number', ...
        'Style', 'text', ...
        'Tag', 'textGridNumber');
    
    editGridNumber = mycontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Parent', groupGridFactors, ...
        'Position', [150 44 50 20], ...
        'String', 36, ...
        'Style', 'edit', ...
        'Tag', 'editGridNumber', ...
        'TooltipString', 'Enter the number of grids');
    set(editGridNumber.Handle, 'Callback', {@editvalidationcallback, editGridNumber, xDataSet})
    
    % Create the z slice edit box.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', groupGridFactors, ...
        'Position', [10 7 100 20], ...
        'String', 'Region z slice', ...
        'Style', 'text', ...
        'Tag', 'textGridZ');
    
    % Get the middle z-slice for the default value.
    zMiddle = round(xDataSet.GetSizeZ/2);
    
    editGridZ = mycontrol(...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Parent', groupGridFactors, ...
        'Position', [150 9 50 20], ...
        'String', zMiddle, ...
        'Style', 'edit', ...
        'Tag', 'editGridZ', ...
        'TooltipString', 'Enter the z slice for the grids');
    set(editGridZ.Handle, 'Callback', {@editvalidationcallback, editGridZ, xDataSet})
    
    % Create the calculate button.
    uicontrol(...
        'Background', bColor, ...
        'Callback', {@pushcalc}, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiEdgeGrids, ...
        'Position', [130 40 90 24], ...
        'String', 'Calculate', ...
        'Style', 'pushbutton', ...
        'Tag', 'pushCalc', ...
        'TooltipString', 'Calculate edge grid intensities');
            
    %% Setup the status bar.
    hStatus = statusbar(guiEdgeGrids, '');
    hStatus.CornerGrip.setVisible(false)
    
    hStatus.ProgressBar.setForeground(java.awt.Color.black)
    hStatus.ProgressBar.setString('')
    hStatus.ProgressBar.setStringPainted(true)
    
    %% Add the GUI to the base's GUI children.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');
    guiChildren = [guiChildren; guiEdgeGrids];
    setappdata(hSortomatoBase, 'guiChildren', guiChildren)
    
    %% Nested function to calculate the edge region intensities
    function pushcalc(varargin)
        % PUSCHCALC
        %
        %
        
        %% Get the parameters from the GUI window.
        imageChannelIdx = get(popupChannel, 'Value');
        maskChannelIdx = get(popupMask, 'Value');
        
        edgeDepth = str2double(get(editGridDepth.Handle, 'String'));
        gridRegionNumber = str2double(get(editGridNumber.Handle, 'String'));
        gridZ = str2double(get(editGridZ.Handle, 'String'));
        
        %% Calculate the data set sampling intervals.
        xInterval = (xDataSet.GetExtendMaxX - xDataSet.GetExtendMinX)/xDataSet.GetSizeX;
        yInterval = (xDataSet.GetExtendMaxY - xDataSet.GetExtendMinY)/xDataSet.GetSizeY;
        zInterval = (xDataSet.GetExtendMaxZ - xDataSet.GetExtendMinZ)/xDataSet.GetSizeZ;
        
        %% Calculate the zero-centerd polar region divisions.
        % Each slice n is defined by the polar coordinate triplet: (0, 0),
        % (r, Theta(n, 1)), (r, Theta(n, 2)).
        rgnRadius = max(xDataSet.GetSizeX, xDataSet.GetSizeY);
        rgnRadians = linspace(0, 2*pi, gridRegionNumber + 1);
        rgnThetas = [rgnRadians(1:end - 1); rgnRadians(2:end)];
                
        %% Allocate a struct for the grid data.
        gridData(1:gridRegionNumber, 1:xDataSet.GetSizeT) = struct(...
            'Area', [], ...
            'Centroid', [], ...
            'MeanIntensity', []);
        
        %% Setup the status bar.
        gridCalcCount = xDataSet.GetSizeT*gridRegionNumber;
        gridCalcIdx = 0;
        
        % Setup the progress bar.
        hStatus.setText('Calculating edge grid intensities');
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setMaximum(gridCalcCount)
        hStatus.ProgressBar.setVisible(true)
        
        %% Calculate the grid intensity values.
        switch char(xDataSet.GetType)
            
            case 'eTypeUInt8'
                for t = 1:xDataSet.GetSizeT
                    %% Get the slice intensity and cell mask.
                    sliceIntensity = xDataSet.GetDataSliceBytes(gridZ - 1, imageChannelIdx - 1, t - 1);
                    sliceMask = logical(xDataSet.GetDataSliceBytes(gridZ - 1, maskChannelIdx - 1, t - 1));
                    
                    %% Identify the cell region and calculate the centroid.
                    cellProps = regionprops(sliceMask, 'Area', 'Centroid', 'PixelIdxList');
                    cellRgnIdx = [cellProps.Area] == max([cellProps.Area]);
                    cellCentroid = cellProps(cellRgnIdx).Centroid;
                    sliceCellMask = false(size(sliceMask));
                    sliceCellMask(cellProps(cellRgnIdx).PixelIdxList) = 1;
                    
                    %% Get the cell edge.
                    edgeDistance = xInterval*bwdist(~sliceCellMask);
                    edgeMask = sliceCellMask & edgeDistance < edgeDepth;
                    
                    %% Calculate the intensity in each edge region.
                    for r = 1:gridRegionNumber
                        % Convert the slice points to cell centered Cartesian coordinates.
                        [sliceXs, sliceYs] = pol2cart(rgnThetas(:, r), ...
                            [rgnRadius; rgnRadius]);
                        sliceXs = [cellCentroid(1); sliceXs + cellCentroid(1)];
                        sliceYs = [cellCentroid(2); sliceYs + cellCentroid(2)];
                        
                        % Calculate the radial region mask and radial edge subregion.
                        rgnMask = poly2mask(sliceXs, sliceYs, ...
                            xDataSet.GetSizeY, xDataSet.GetSizeX);
                        gridMask = rgnMask & edgeMask;
                        
                        % Get the region properties.
                        rtProps = regionprops(...
                            gridMask, sliceIntensity, ...
                            'Area', 'Centroid', 'MeanIntensity');
                        
                        % If the region union caused a split into multiple
                        % blobs, find the one closest to the cell center.
                        if length(rtProps) > 1
                            rtCentroids = vertcat(rtProps.Centroid);
                            rtDistances = sqrt(sum(bsxfun(...
                                @minus, rtCentroids, cellCentroid).^2, 2));
                            rtIdx = min(rtDistances);
                            
                        else
                            rtIdx = 1;
                            
                        end % if
                        
                        % Add the data to the struct.
                        gridData(r, t) = rtProps(rtIdx);
                        
                        % Update the progress bar.
                        gridCalcIdx = gridCalcIdx + 1;
                        hStatus.ProgressBar.setValue(gridCalcIdx)
                    end % for r
                end % for t
                
            case 'eTypeUInt16'
                for t = 1:xDataSet.GetSizeT
                    %% Get the slice intensity and cell mask.
                    sliceIntensity = xDataSet.GetDataSliceShorts(gridZ - 1, imageChannelIdx - 1, t - 1);
                    sliceMask = logical(xDataSet.GetDataSliceShorts(gridZ - 1, maskChannelIdx - 1, t - 1));
                    
                    %% Identify the cell region and calculate the centroid.
                    cellProps = regionprops(sliceMask, 'Area', 'Centroid', 'PixelIdxList');
                    cellRgnIdx = [cellProps.Area] == max([cellProps.Area]);
                    cellCentroid = cellProps(cellRgnIdx).Centroid;
                    sliceCellMask = false(size(sliceMask));
                    sliceCellMask(cellProps(cellRgnIdx).PixelIdxList) = 1;
                    
                    %% Get the cell edge.
                    edgeDistance = xInterval*bwdist(~sliceCellMask);
                    edgeMask = sliceCellMask & edgeDistance < edgeDepth;
                    
                    %% Calculate the intensity in each edge region.
                    for r = 1:gridRegionNumber
                        % Convert the slice points to cell centered Cartesian coordinates.
                        [sliceXs, sliceYs] = pol2cart(rgnThetas(:, r), ...
                            [rgnRadius; rgnRadius]);
                        sliceXs = [cellCentroid(1); sliceXs + cellCentroid(1)];
                        sliceYs = [cellCentroid(2); sliceYs + cellCentroid(2)];
                        
                        % Calculate the radial region mask and radial edge subregion.
                        rgnMask = poly2mask(sliceXs, sliceYs, ...
                            xDataSet.GetSizeY, xDataSet.GetSizeX);
                        gridMask = rgnMask & edgeMask;
                        
                        % Get the region properties.
                        rtProps = regionprops(...
                            gridMask, sliceIntensity, ...
                            'Area', 'Centroid', 'MeanIntensity');
                        
                        % If the region union caused a split into multiple
                        % blobs, find the one closest to the cell center.
                        if length(rtProps) > 1
                            rtCentroids = vertcat(rtProps.Centroid);
                            rtDistances = sqrt(sum(bsxfun(...
                                @minus, rtCentroids, cellCentroid).^2, 2));
                            [~, rtIdx] = min(rtDistances);
                            
                        else
                            rtIdx = 1;
                            
                        end % if
                        
                        % Add the data to the struct.
                        gridData(r, t) = rtProps(rtIdx);
                        
                        % Update the progress bar.
                        gridCalcIdx = gridCalcIdx + 1;
                        hStatus.ProgressBar.setValue(gridCalcIdx)
                    end % for r
                end % for t
                
            case 'eTypeFloat'
                for t = 1:xDataSet.GetSizeT
                    %% Get the slice intensity and cell mask.
                    sliceIntensity = xDataSet.GetDataSliceFloats(gridZ - 1, imageChannelIdx - 1, t - 1);
                    sliceMask = logical(xDataSet.etDataSliceFloats(gridZ - 1, maskChannelIdx - 1, t - 1));
                    
                    %% Identify the cell region and calculate the centroid.
                    cellProps = regionprops(sliceMask, 'Area', 'Centroid', 'PixelIdxList');
                    cellRgnIdx = [cellProps.Area] == max([cellProps.Area]);
                    cellCentroid = cellProps(cellRgnIdx).Centroid;
                    sliceCellMask = false(size(sliceMask));
                    sliceCellMask(cellProps(cellRgnIdx).PixelIdxList) = 1;
                    
                    %% Get the cell edge.
                    edgeDistance = xInterval*bwdist(~sliceCellMask);
                    edgeMask = sliceCellMask & edgeDistance < edgeDepth;
                    
                    %% Calculate the intensity in each edge region.
                    for r = 1:gridRegionNumber
                        % Convert the slice points to cell centered Cartesian coordinates.
                        [sliceXs, sliceYs] = pol2cart(rgnThetas(:, r), ...
                            [rgnRadius; rgnRadius]);
                        sliceXs = [cellCentroid(1); sliceXs + cellCentroid(1)];
                        sliceYs = [cellCentroid(2); sliceYs + cellCentroid(2)];
                        
                        % Calculate the radial region mask and radial edge subregion.
                        rgnMask = poly2mask(sliceXs, sliceYs, ...
                            xDataSet.GetSizeY, xDataSet.GetSizeX);
                        gridMask = rgnMask & edgeMask;
                        
                        % Get the region properties.
                        rtProps = regionprops(...
                            gridMask, sliceIntensity, ...
                            'Area', 'Centroid', 'MeanIntensity');
                        
                        % If the region union caused a split into multiple
                        % blobs, find the one closest to the cell center.
                        if length(rtProps) > 1
                            rtCentroids = vertcat(rtProps.Centroid);
                            rtDistances = sqrt(sum(bsxfun(...
                                @minus, rtCentroids, cellCentroid).^2, 2));
                            rtIdx = min(rtDistances);
                            
                        else
                            rtIdx = 1;
                            
                        end % if
                        
                        % Add the data to the struct.
                        gridData(r, t) = rtProps(rtIdx);
                        
                        % Update the progress bar.
                        gridCalcIdx = gridCalcIdx + 1;
                        hStatus.ProgressBar.setValue(gridCalcIdx)
                    end % for r
                end % for t
                
        end % switch
        
        %% Create spot data lists from the grid regions.
        % Convert the grid coordinates to Imaris mesh coordinates.
        gridPositions = circshift(vertcat(gridData.Centroid), [0, 1]);
        gridPositions = bsxfun(@times, gridPositions - 1, [xInterval, yInterval]);
        gridPositions = [gridPositions, repmat(0.5*zInterval, [length(gridPositions), 1])];
        
        % Calculate an equivalent radius for the grid regions.
        gridRadii = sqrt(xInterval*yInterval*[gridData.Area]/(4*pi));
        
        % Get the grid intensities. They will be added as custom
        % because the grid regions do not match the spot shape profile.
        gridIntensities = [gridData.MeanIntensity];
        
        gridTimes = repmat((1:xDataSet.GetSizeT), [gridRegionNumber, 1]);
        gridTimes = gridTimes(:);
        
        %% Generate track edges for the regions.
        % Replicate the first grid track.
        baseEdges = transpose((1:gridRegionNumber:gridCalcCount) - 1);
        baseEdges = [baseEdges(1:end - 1), baseEdges(2:end)];
        baseEdges = repmat(baseEdges, [gridRegionNumber, 1]);
        
        % Create an array to shift the indices for the tracks.
        rShifts = 0:gridRegionNumber - 1;
        rShifts = repmat(rShifts, [2*(xDataSet.GetSizeT - 1), 1]);
        rShifts = reshape(rShifts, [2, numel(rShifts)/2])';
        
        % Create the final track edges array.
        edgesArray = baseEdges + rShifts;
        
        %% Create Imaris Spots from the grid regions.
        xSpots = xImarisApp.GetFactory.CreateSpots;
        xSpots.Set(gridPositions, gridTimes - 1, gridRadii)
        xSpots.SetTrackEdges(edgesArray)
        
        %% Add the spots to the data set.
        xImarisApp.GetSurpassScene.AddChild(xSpots, -1)
        
        %% Create a custom statistic for the grid spots.
        % Create the ID list.
        gridSpotIDs = 0:gridCalcCount - 1;

        % Create the interior intensity stat name list.
        gridIntensityNames = repmat({'Grid intensity'}, [gridCalcCount 1]);

        % Create the unit list.
        statUnits = repmat({''}, [gridCalcCount 1]); 

        % Assemble the factors cell array.
        statFactors = cell(4, gridCalcCount);

        % Set the Category to Surfaces.
        statFactors(1, :) = repmat({'Spot'}, [gridCalcCount 1]);

        % Set the Channels.
        statFactors(2, :) = repmat({num2str(imageChannelIdx)}, [gridCalcCount 1]);

        % Set the Collection to an empty string.
        statFactors(3, :) = repmat({''}, [gridCalcCount 1]);
       
        % Set the Time.
        statFactors(4, :) = num2cell(gridTimes);

        % Convert the time points to strings...
        statFactors(4, :) = cellfun(@num2str, statFactors(4, :), ...
            'UniformOutput', 0);

        % Create the factor names.
        factorNames = {'Category'; 'Channel'; 'Collection'; 'Time'};

        % Send the interior intensities to Imaris.
        xSpots.AddStatistics(gridIntensityNames, gridIntensities(:), statUnits, ...
            statFactors, factorNames, gridSpotIDs)        
    
        %% Reset the progress and status bars.
        hStatus.setText('')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setVisible(false)
    end % pushcalc    
end % sortomatoedgegrids


%% Channel refresh function
function pushchannelrefresh(hObject, ~, xDataSet)
    %
    %
    %

    %% Get the data channels.
    imarisChannels = cell(xDataSet.GetSizeC, 1);
    for cr = 1:xDataSet.GetSizeC
        channelString = char(xDataSet.GetChannelName(cr - 1));
        if strcmp(channelString, '(name not specified)')
            imarisChannels{cr} = ['Channel ' num2str(cr)];

        else
            imarisChannels{cr} = char(xDataSet.GetChannelName(cr - 1));

        end % if
    end % for cr

    %% Update the popup menu strings.
    popupChannel = findobj(get(hObject, 'Parent'), 'Tag', 'popupChannel');
    popupMask = findobj(get(hObject, 'Parent'), 'Tag', 'popupMask');
    
    set([popupChannel, popupMask], 'String', imarisChannels)

    %% Reset the channel selection.
    set(popupChannel, 'Value', 1)

    %% If there is a channel with mask in the name, select it with.
    maskChannelIdxs = ~cellfun(@isempty, ...
        regexp(imarisChannels, 'Mask|mask', 'Start', 'Once'));

    if any(maskChannelIdxs)
        set(popupMask, 'Value', find(maskChannelIdxs, 1, 'first'))

    else
        set(popupMask, 'Value', 2)

    end % if
end % pushrefresh


%% Callback function to validate editbox changes
function editvalidationcallback(hObject, ~, hObjectContainer, xDataSet)
    % EDITVALIDATIONCALLBACK Verify a string can convert to numeric
    %
    %

    %% Update the editbox value if the input is numeric.
    newValue = str2double(get(hObject, 'String'));

    if isnan(newValue) || newValue < 0
        set(hObject, 'String', hObjectContainer.OldString)

    else
        % If the number of objects or z-slice was edited, round to the
        % nearest whole number and check for a z in range.
        switch get(hObject, 'Tag')

            case 'editGridNumber'
                newValue = round(newValue);

            case 'editGridZ'
                newValue = round(newValue);

                if newValue > xDataSet.GetSizeZ
                    newValue = xDataSet.GetSizeZ;

                elseif newValue < 1
                    newValue = 1;

                end % if

        end % switch

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