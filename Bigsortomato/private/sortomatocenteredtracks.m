function sortomatocenteredtracks(~, ~, guiSortomato)
    % SORTOMATOCENTEREDTRACKS Plto tracks with a common origin
    %   Detailed explanation goes here
    %
    %   ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %   license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Check for an already-running GUI.
    guiChildren = getappdata(guiSortomato, 'guiChildren');
    
    if ~isempty(guiChildren)
        guiCenteredTracks = findobj(guiChildren, 'Tag', 'guiCenteredTracks');
        
        if ~isempty(guiCenteredTracks)
            figure(guiCenteredTracks)
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
    
    %% Set the figure and font colors.
    if all(get(guiSortomato, 'Color') == [0 0 0])
        bColor = 'k';
        fColor = 'w';

    else
        bColor = 'w';
        fColor = 'k';
        
    end % if
    
    %% Create a GUI to select objects.
    sortomatoPos = get(guiSortomato, 'Position');
    
    guiWidth = 230;
    guiHeight = 133;
    guiPos = [...
        sortomatoPos(1) + sortomatoPos(3)/2 - guiWidth/2, ...
        sortomatoPos(2) + sortomatoPos(4) - guiHeight - 25, ...
        guiWidth, ...
        guiHeight];
    
    guiCenteredTracks = figure(...
        'CloseRequestFcn', {@closerequestfcn, guiSortomato}, ...
        'Color', bColor, ...
        'MenuBar', 'None', ...
        'Name', 'Centered plots', ...
        'NumberTitle', 'Off', ...
        'Position', guiPos, ...
        'Resize', 'Off', ...
        'Tag', 'guiCenteredTracks');
    
    % Create the object selection popup menu.
    uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'HorizontalAlign', 'Left', ...
        'Parent', guiCenteredTracks, ...
        'Position', [10 86 108 24], ...
        'String', 'Objects', ...
        'Style', 'text', ...
        'Tag', 'textObjects');
    
    popupObjects = uicontrol(...
        'Background', bColor, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiCenteredTracks, ...
        'Position', [120 90 100 24], ...
        'String', {surpassObjects.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupObjects', ...
        'TooltipString', 'Select objects to plot', ...
        'Value', 1);
    
    % Create the plot button.
    uicontrol(...
        'Background', bColor, ...
        'Callback', {@pushplotcallback}, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', guiCenteredTracks, ...
        'Position', [130 40 90 24], ...
        'String', 'Plot', ...
        'Style', 'pushbutton', ...
        'Tag', 'pushPlot', ...
        'TooltipString', 'Plot centered tracks');
    
    %% Setup the status bar.
    hStatus = statusbar(guiCenteredTracks, '');
    hStatus.CornerGrip.setVisible(false)
    
    hStatus.ProgressBar.setForeground(java.awt.Color.black)
    hStatus.ProgressBar.setString('')
    hStatus.ProgressBar.setStringPainted(true)
    
    %% Add the GUI to the base's GUI children.
    guiChildren = getappdata(guiSortomato, 'guiChildren');
    guiChildren = [guiChildren; guiCenteredTracks];
    setappdata(guiSortomato, 'guiChildren', guiChildren)
    
    %% Nested function to plot zero-centered tracks
    function pushplotcallback(varargin)
        % PUSHPLOTCALLBACK Plot selected object tracks centered at [0, 0, 0].
        %
        %
        
        %% Get the selected object.
        plotObjectIdx = get(popupObjects, 'Value');
        xObject = surpassObjects(plotObjectIdx).ImarisObject;

        %% Get the Surpass object data.
        if xImarisApp.GetFactory.IsSpots(xObject)
            % Get the spot positions.
            objectPos = xObject.GetPositionsXYZ;
            objectTimes = xObject.GetIndicesT;
            
        else
            % Get the number of surfaces.
            surfaceCount = xObject.GetNumberOfSurfaces;

            % Get the surface positions and times.
            objectPos = zeros(surfaceCount, 3);
            objectTimes = zeros(size(surfaceCount));
            for s = 1:surfaceCount
                objectPos(s, :) = xObject.GetCenterOfMass(s - 1);
                objectTimes(s) = xObject.GetTimeIndex(s - 1);
            end % s

        end % if

        %% Get the track information.
        trackIDs = xObject.GetTrackIds;
        trackEdges = xObject.GetTrackEdges;
        trackLabels = unique(trackIDs);

        %% If there are no tracks, return.
        if isempty(trackEdges)
            return
        end % if
        
        %% Create a figure for plotting.
        [graphTracks, axesGraph] = sortomatocenteredtracksgraph(...
            guiCenteredTracks, xObject, guiSortomato);
                        
        %% Create a cell to store the data for exporting the data.
        centeredTracks = cell(xImarisApp.GetDataSet.GetSizeT + 1, 3*length(trackLabels));
        centeredTracks(1, 1) = {'Time Index'};
        centeredTracks(1, 3:3:end) = num2cell(trackLabels');
        centeredTracks(2:end, 1) = num2cell(transpose(1:xImarisApp.GetDataSet.GetSizeT));

        %% Translate all the tracks to a common origin and plot.
        % Setup the progress bar.
        hStatus.setText('Plotting tracks');
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setMaximum(length(trackLabels))
        hStatus.ProgressBar.setVisible(true)
        
        % Create a color sequence for the lines.
        lineColors = lines(length(trackLabels));
        
        for r = 1:length(trackLabels)
            % Get indices for the track.
            rEdges = trackEdges(trackIDs == trackLabels(r), :);
            rSpots = unique(rEdges);

            % Get the track positions.
            rPos = objectPos(rSpots + 1, :);

            % Shift the track coordinates to place the origin at zero.
            cPos = bsxfun(@minus, rPos, rPos(1, :));

            % Plot the shifted track.
            line(cPos(:, 1), cPos(:, 2), cPos(:, 3), ...
                'Color', lineColors(r, :), ...
                'DisplayName', ['Track ' num2str(r)], ...
                'LineWidth', 1, ...
                'Parent', axesGraph) 

            % Add the track positions to the list of all track data.
            rTimeIdxs = objectTimes(rSpots + 1) + 1;
            centeredTracks(rTimeIdxs + 1, 3*r - 1:3*r + 1) = num2cell(cPos);
            
            % Update the waitbar.
            hStatus.ProgressBar.setValue(r)
        end % for r
        
        % Reset the status bar.
        hStatus.setText('')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setVisible(false)
        
        %% Format the axes limits for the plotted data.
        axis(axesGraph, 'equal')
        
        % Make the axes symmetric about zero.
        % For x:
        xRange = xlim(axesGraph);
        xExtreme = ceil(max(abs(xRange)));
        xlim(axesGraph, [-xExtreme xExtreme])
        
        % For y:
        yRange = ylim(axesGraph);
        yExtreme = ceil(max(abs(yRange)));
        ylim(axesGraph, [-yExtreme yExtreme])
        
        % For z:
        zRange = zlim(axesGraph);
        zExtreme = ceil(max(abs(zRange)));
        zlim(axesGraph, [-zExtreme zExtreme])
        
        view(axesGraph, [-37.5, 30])
        
        %% Store the plot data for export.
        setappdata(graphTracks, 'centeredTracks', centeredTracks)
    end % pushplot    
end % sortomatocenteredtracks


function closerequestfcn(guiCenteredTracks, ~, guiSortomato)
    % Close centered tracks sub-GUI
    %
    %
    
    %% Remove any open graph handles from the base's appdata and delete.
    % Find any open centered plot graphs.
    graphChildren = getappdata(guiSortomato, 'graphChildren');
    graphTracks = findobj(graphChildren, 'Tag', 'graphTracks');

    % Delete the graphs and any adjustment windows that are open.
    for c = 1:length(graphTracks)
        guiLimits = getappdata(graphTracks(c), 'guiLimits');
        if ~isempty(guiLimits)
            delete(guiLimits)
        end % if

        guiView = getappdata(graphTracks(c), 'guiView');
        if ~isempty(guiView)
            delete(guiView)
        end % if
    end % for p

    delete(graphChildren(ismember(graphChildren, graphTracks)))
    graphChildren(ismember(graphChildren, graphTracks)) = [];
    setappdata(guiSortomato, 'graphChildren', graphChildren)

    %% Remove the GUI's handle from the base's appdata and delete.
    guiChildren = getappdata(guiSortomato, 'guiChildren');

    guiIdx = guiChildren == guiCenteredTracks;
    guiChildren = guiChildren(~guiIdx);
    setappdata(guiSortomato, 'guiChildren', guiChildren)
    delete(guiCenteredTracks);
end % closerequestfcn