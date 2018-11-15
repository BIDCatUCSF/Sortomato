function sortomatoarrest(~, ~, hSortomatoBase)
    % SORTOMATOARREST Summary of this function goes here
    %   Detailed explanation goes here
    %
    %   ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %   license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Check for an already-running GUI.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');
    
    if ~isempty(guiChildren)
        guiArrest = findobj(guiChildren, 'Tag', 'guiArrest');
        
        if ~isempty(guiArrest)
            figure(guiArrest)
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
    
    %% Create a GUI to select objects.
    sortomatoPos = get(hSortomatoBase, 'Position');
    
    guiWidth = 230;
    guiHeight = 239;
    guiPos = [...
        sortomatoPos(1) + sortomatoPos(3)/2 - guiWidth/2, ...
        sortomatoPos(2) + sortomatoPos(4) - guiHeight - 25, ...
        guiWidth, ...
        guiHeight];
    
    guiArrest = figure(...
        'CloseRequestFcn', {@closerequestfcn, hSortomatoBase}, ...
        'Color', bColor, ...
        'MenuBar', 'None', ...
        'Name', 'Arrest coefficient calculation', ...
        'NumberTitle', 'Off', ...
        'Position', guiPos, ...
        'Resize', 'Off', ...
        'Tag', 'guiArrest');
        
    % Create the object selection popup menu.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiArrest, ...
        'Position', [10 192 108 24], ...
        'String', 'Objects', ...
        'Style', 'text', ...
        'Tag', 'textObjects');
    
    popupObjects = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiArrest, ...
        'Position', [120 196 100 24], ...
        'String', {surpassObjects.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupObjects', ...
        'TooltipString', 'Select objects for arrest coefficient calculation', ...
        'Value', 1);
    
    % Create the arrest factor edit boxes.
    panelArrestFactors = uipanel(...
        'BackgroundColor', bColor, ...
        'BorderType', 'Line', ...
        'FontSize', 12, ...
        'ForegroundColor', fColor, ...
        'HighlightColor', fColor, ...
        'Parent', guiArrest, ...
        'Position', [10 85 210 85]./[guiPos(3) guiPos(4) guiPos(3) guiPos(4)], ...
        'Tag', 'panelArrestFactors', ...
        'Title', 'Arrest factors', ...
        'TitlePosition', 'Centertop', ...
        'Units', 'Pixels');
    uistack(panelArrestFactors, 'bottom')
    
    uicontrol(...
        'FontSize', 10, ...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiArrest, ...
        'Position', [10 42 110 20], ...
        'Parent', panelArrestFactors, ...
        'String', 'Speed (um/min)', ...
        'Style', 'text', ...
        'Tag', 'textSpeed')
    
    editSpeed = mycontrol(...
        'FontSize', 10, ...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Parent', panelArrestFactors, ...
        'Position', [150 44 50 20], ...
        'String', 1, ...
        'Style', 'edit', ...
        'Tag', 'editArrestSpeed', ...
        'TooltipString', 'Enter the maximum arrest speed');
    set(editSpeed.Handle, 'Callback', {@editvalidationcallback, editSpeed})    
        
    uicontrol(...
        'FontSize', 10, ...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', panelArrestFactors, ...
        'Position', [10 7 100 20], ...
        'String', 'Duration (min)', ...
        'Style', 'text', ...
        'Tag', 'textDuration')
    
    editDuration = mycontrol(...
        'FontSize', 10, ...
        'Background', bColor, ...
        'FontSize', 10, ...
        'Foreground', fColor, ...
        'Parent', panelArrestFactors, ...
        'Position', [150 9 50 20], ...
        'String', 1, ...
        'Style', 'edit', ...
        'Tag', 'editDuration', ...
        'TooltipString', 'Enter the minimum arrest duration');
    set(editDuration.Handle, 'Callback', {@editvalidationcallback, editDuration})    
    
    % Create the calculate button.
    uicontrol(...
        'Background', bColor, ...
        'Callback', {@pushcalc}, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiArrest, ...
        'Position', [130 40 90 24], ...
        'String', 'Calculate', ...
        'Style', 'pushbutton', ...
        'Tag', 'pushCalc', ...
        'TooltipString', 'Calculate arrest coefficients');
    
    %% Setup the status bar.
    hStatus = statusbar(guiArrest, '');
    hStatus.CornerGrip.setVisible(false)
    
    hStatus.ProgressBar.setForeground(java.awt.Color.black)
    hStatus.ProgressBar.setString('')
    hStatus.ProgressBar.setStringPainted(true)
    
    %% Add the GUI to the base's GUI children.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');
    guiChildren = [guiChildren; guiArrest];
    setappdata(hSortomatoBase, 'guiChildren', guiChildren)
    
    %% Nested function to perform turning angle calculation
    function pushcalc(varargin)
        % Calculate arrest coefficients
        %
        %
        
        %% Get the seleted Surpass object.
        arrestObjectIdx = get(popupObjects, 'Value');
        xObject = surpassObjects(arrestObjectIdx).ImarisObject;
        
        %% Get the arrest criteria.
        speedCriteria = str2double(get(editSpeed.Handle, 'String'));
        durationCriteria = str2double(get(editDuration.Handle, 'String'));
                
        %% Setup the status bar.
        hStatus.setText('Calculating arrest coefficients')

        %% Get the Surpass object data.
        if xImarisApp.GetFactory.IsSpots(xObject)
            % Get the spot positions.
            objectPos = xObject.GetPositionsXYZ;

            % Get the spot times.
            objectTimes = xObject.GetIndicesT;

        else
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

        %% Get the time calibration strings and convert to serial minute values.
        timeCell = cell(xImarisApp.GetDataSet.GetSizeT, 1);

        for t = 1:xImarisApp.GetDataSet.GetSizeT
            timeCell{t} = char(xImarisApp.GetDataSet.GetTimePoint(t - 1));
        end % for t

        % Convert to serial minute values.
        acquireTimes = datenum(timeCell, 'yyyy-mm-dd HH:MM:SS')*(24*60);

        %% Create a list of object indexes and get the track information.
        % Get the track information.
        objectIDs = xObject.GetTrackIds;
        objectEdges = xObject.GetTrackEdges;
        trackLabels = unique(objectIDs);

        %% Calculate the arrest coefficients.
        % Allocate a vector for the turning angle data.
        trackArrestFxs = zeros(size(trackLabels));

        % Setup the progress bar.
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setMaximum(length(trackLabels))
        hStatus.ProgressBar.setVisible(true)

        % Calculate the turning angle for all the tracks.
        for r = 1:length(trackLabels)
            % Get indices for the track.
            rEdges = objectEdges(objectIDs == trackLabels(r), :);
            rObjects = unique(rEdges);

            % Get the track positions.
            rPos = objectPos(rObjects + 1, :);

            % Get the track times and convert to 1-based indexes.
            rTimeIdxs = objectTimes(rObjects + 1);

            % Calculate the track movement vectors.
            rVectors = diff(rPos);

            % Calculate the time deltas.
            rDiffTs = diff(acquireTimes(rTimeIdxs + 1));

            % Calculate the instantaneous speeds.
            rSpeeds = sqrt(sum(rVectors.^2, 2))./rDiffTs;

            % Find the arrested time points.
            rStops = rSpeeds < speedCriteria;

            % Pad the stops vector.
            arrestRuns = [0; rStops; 0];

            % Find the nonarrest indices.
            motileIdxs = find(~arrestRuns);

            % Calculate the pause durations.
            arrestLengths = diff(motileIdxs) - 1;

            % Keep only the pauses greater than the arrest duration criteria.
            rArrests = arrestLengths(arrestLengths > durationCriteria);

            % Calculate the fraction of the track spent in an arrested state.
            arrestFx = sum(rArrests)/size(rTimeIdxs, 1);

            % Add the arest coefficient to the list.
            trackArrestFxs(r) = arrestFx;

            % Update the  progress bar.
            hStatus.ProgressBar.setValue(r)
        end % for r

        %% Transfer the track arrest coefficient stats to Imaris.
        % Update the status and progresss bar.
        hStatus.setText('Transferring arrest coefficients')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setMaximum(1)

        % Create the stat name list.
        arrestNames = repmat({'Track arrest coefficient'}, size(trackLabels));

        % Create the unit list.
        imarisUnits = '';
        arrestUnits = repmat({imarisUnits}, size(trackLabels)); 

        % Assemble the factors cell array.
        arrestFactors = cell(3, length(trackLabels));

        % Set the Category to Track.
        arrestFactors(1, :) = repmat({'Track'}, size(trackLabels));

        % Set the Collection to any empty string.
        arrestFactors(2, :) = repmat({''}, size(trackLabels));

        % Set the Time to an empty string.
        arrestFactors(3, :) = repmat({''}, size(trackLabels));

        % Create the factor names.
        factorNames = {'Category'; 'Collection'; 'Time'};

        % Send the stats to Imaris.
        xObject.AddStatistics(arrestNames, trackArrestFxs, arrestUnits, ...
            arrestFactors, factorNames, trackLabels)

        % Update the progress bar.
        hStatus.ProgressBar.setValue(1)

        %% Reset the progress and status bars.
        hStatus.setText('')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setVisible(false)
    end % pushcalc    
end % sortomatoarrest


%% Callback function to validate editbox changes
function editvalidationcallback(hObject, ~, hObjectContainer)
    % EDITVALIDATIONCALLBACK Verify a string can convert to numeric
    %
    %

    %% Update the editbox value if the input is numeric.
    newValue = str2double(get(hObject, 'String'));

    if isnan(newValue) || newValue < 0
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