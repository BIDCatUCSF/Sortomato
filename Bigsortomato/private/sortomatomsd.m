function sortomatomsd(~, ~, hSortomatoBase)
    % SORTOMATOMSD Calculate mean-squared displacements
    %   Detailed explanation goes here
    %
    %  ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %  license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Check for an already-running GUI.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');
    
    if ~isempty(guiChildren)
        guiMSD = findobj(guiChildren, 'Tag', 'guiMSD');
        
        if ~isempty(guiMSD)
            figure(guiMSD)
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
    guiHeight = 133;
    guiPos = [...
        sortomatoPos(1) + sortomatoPos(3)/2 - guiWidth/2, ...
        sortomatoPos(2) + sortomatoPos(4) - guiHeight - 25, ...
        guiWidth, ...
        guiHeight];
    
    guiMSD = figure(...
        'CloseRequestFcn', {@closerequestfcn, hSortomatoBase}, ...
        'Color', bColor, ...
        'MenuBar', 'None', ...
        'Name', 'Mean-squared displacement calculation', ...
        'NumberTitle', 'Off', ...
        'Position', guiPos, ...
        'Resize', 'Off', ...
        'Tag', 'guiMSD');
    
    % Create the object selection popup menu.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Position', [10 86 108 24], ...
        'String', 'Objects', ...
        'Style', 'text', ...
        'Tag', 'textObjects');
    
    popupObjects = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiMSD, ...
        'Position', [120 90 100 24], ...
        'String', {surpassObjects.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupObjects', ...
        'TooltipString', 'Select objects for turning angle calculation', ...
        'Value', 1);
    
    % Create the calculate button.
    uicontrol(...
        'Background', bColor, ...
        'Callback', {@pushcalc}, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiMSD, ...
        'Position', [130 40 90 24], ...
        'String', 'Calculate', ...
        'Style', 'pushbutton', ...
        'Tag', 'pushCalc', ...
        'TooltipString', 'Calculate turing angles');
    
    %% Setup the status bar.
    hStatus = statusbar(guiMSD, '');
    hStatus.CornerGrip.setVisible(false)
    
    hStatus.ProgressBar.setForeground(java.awt.Color.black)
    hStatus.ProgressBar.setString('')
    hStatus.ProgressBar.setStringPainted(true)
    
    %% Add the GUI to the base's GUI children.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');
    guiChildren = [guiChildren; guiMSD];
    setappdata(hSortomatoBase, 'guiChildren', guiChildren)
    
    %% Nested function to perform mean-squared displacement calculation
    function pushcalc(varargin)
        % pushcalc Calculate the track MSDs
        %
        %
        
        %% Get the seleted Surpass object.
        msdObjectIdx = get(popupObjects, 'Value');
        xObject = surpassObjects(msdObjectIdx).ImarisObject;
        
        %% Setup the status bar.
        hStatus.setText('Calculating MSDs')

        %% Get the dataset sampling interval.
        timeDelta = xImarisApp.GetDataSet.GetTimePointsDelta;
        
        %% Get the Surpass object data.
        if xImarisApp.GetFactory.IsSpots(xObject)
            % Get the spot positions.
            objectPos = xObject.GetPositionsXYZ;

            % Get the spot times.
            objectTimeIdxs = xObject.GetIndicesT;
            
        else
            % Get the number of surfaces.
            surfaceCount = xObject.GetNumberOfSurfaces;
            
            % Get the surface positions and times.
            objectPos = zeros(surfaceCount, 3);
            objectTimeIdxs = zeros(surfaceCount, 1);
            for s = 1:surfaceCount
                objectPos(s, :) = xObject.GetCenterOfMass(s - 1);
                objectTimeIdxs(s) = xObject.GetTimeIndex(s - 1);
            end % s
            
        end % if
        
        %% Create a list of object indexes and get the track information.        
        % Get the track information.
        trackIDs = xObject.GetTrackIds;
        trackEdges = xObject.GetTrackEdges;
        trackLabels = unique(trackIDs);
        
        % Setup the progress bar.
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setMaximum(length(trackLabels))
        hStatus.ProgressBar.setVisible(true)

        % Allocate a cell for track MSD series.
        objectTrajectories = cell(1, length(trackLabels));

        for r = 1:length(trackLabels)
            % Get the trajectory.
            rEdges = trackEdges(trackIDs == trackLabels(r), :);
            rSpots = unique(rEdges);

            % Get the track positions.
            rPos = objectPos(rSpots + 1, :);
            
            % Get the track time indices and convert to time values.
            rTimeIdxs = single(objectTimeIdxs(rSpots + 1));
            rTimes = rTimeIdxs*timeDelta;
            
            % Add the trajectory to the cell.
            objectTrajectories{r} = [rTimes, rPos];
            
            hStatus.ProgressBar.setValue(r)
        end % for r

        %% Calculate the MSDs.
        % Create the msdanalyzer object.
        objectMSD = msdanalyzer(3, '\mum', 's');
        objectMSD = objectMSD.addAll(objectTrajectories);
        objectMSD = objectMSD.computeMSD;
            
        %% Create a graph of the MSDs.
        % Create the formatted msd figure window.
        [graphMSD, guiMSDAxes] = sortomatomsdgraph(guiMSD, xObject, hSortomatoBase);

        %% Plot the MSD sequence.
        lineColor = rgb32bittotriplet(xObject.GetColorRGBA);
        objectMSD.plotMeanMSD(guiMSDAxes, true, [], lineColor);
        
        %% Store the MSD data.
        setappdata(graphMSD, 'objectMSD', objectMSD)
        setappdata(graphMSD, 'xObject', xObject)
        
        %% Reset the status bar.
        hStatus.setText('')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setVisible(false)
    end % pushcalc
end % sortomatomeansquareddisplacement


function closerequestfcn(hObject, ~, hSortomatoBase)
    % Close sortomato sub-GUIs
    %
    %
    
    %% Remove any open MSD graph handles from the base's appdata and delete.
    % Find any open MSD graphs.
    graphChildren = getappdata(hSortomatoBase, 'graphChildren');
    msdGraphs = findobj(graphChildren, 'Tag', 'graphMSD');

    % Delete the graphs and any limit adjustment windows that are open.
    for c = 1:length(msdGraphs)
        hLimits = getappdata(msdGraphs(c), 'hLimits');
        if ~isempty(hLimits)
            delete(hLimits)
        end % if
    end % for p

    delete(graphChildren(ismember(graphChildren, msdGraphs)))
    graphChildren(ismember(graphChildren, msdGraphs)) = [];
    setappdata(hSortomatoBase, 'graphChildren', graphChildren)

    %% Remove the GUI's handle from the base's appdata and delete.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');

    guiIdx = guiChildren == hObject;
    guiChildren = guiChildren(~guiIdx);
    setappdata(hSortomatoBase, 'guiChildren', guiChildren)
    delete(hObject);
end % closerequestfcn