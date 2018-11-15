function sortomizercenteredtracks(~, ~, hSortomizerBase)
    % SORTOMIZERCENTEREDTRACKS Plot tracks with a common origin
    %   Detailed explanation goes here
    %
    %   ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %   license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Check for an already-running GUI.
    guiChildren = getappdata(hSortomizerBase, 'guiChildren');
    
    if ~isempty(guiChildren)
        hCenteredTracks = findobj(guiChildren, 'Tag', 'hCenteredTracks');
        
        if ~isempty(hCenteredTracks)
            figure(hCenteredTracks)
            return
        end % if
    end % if
    
    %% Get the Surpass Spots and Surfaces.
    xImarisApp = getappdata(hSortomizerBase, 'xImarisApp');
    surpassObjects = xtgetsporfaces(xImarisApp, 'Both');

    % If the scene has no Spots or Surfaces, return.
    if isempty(surpassObjects)
        return
    end % if
    
    %% Set the figure and font colors.
    if all(get(hSortomizerBase, 'Color') == [0 0 0])
        bColor = 'k';
        fColor = 'w';

    else
        bColor = 'w';
        fColor = 'k';
        
    end % if
    
    %% Create a GUI to select objects.
    sortomizerPos = get(hSortomizerBase, 'Position');
    
    guiWidth = 230;
    guiHeight = 133;
    guiPos = [...
        sortomizerPos(1) + sortomizerPos(3)/2 - guiWidth/2, ...
        sortomizerPos(2) + sortomizerPos(4) - guiHeight - 25, ...
        guiWidth, ...
        guiHeight];
    
    hCenteredTracks = sortomizercenteredtracksgraph(...
        'CloseRequestFcn', {@closerequestfcn, hSortomizerBase}, ...
        'Color', bColor, ...
        'MenuBar', 'None', ...
        'Name', 'Centered plots', ...
        'NumberTitle', 'Off', ...
        'Position', guiPos, ...
        'Resize', 'Off', ...
        'Tag', 'hCenteredTracks');
    
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
        'Parent', hCenteredTracks, ...
        'Position', [120 90 100 24], ...
        'String', {surpassObjects.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupObjects', ...
        'TooltipString', 'Select objects to plot', ...
        'Value', 1);
    
    % Create the plot button.
    uicontrol(...
        'Background', bColor, ...
        'Callback', {@pushplot}, ...
        'FontSize', 12, ...
        'Foreground', fColor, ...
        'Parent', hCenteredTracks, ...
        'Position', [130 40 90 24], ...
        'String', 'Plot', ...
        'Style', 'pushbutton', ...
        'Tag', 'pushPlot', ...
        'TooltipString', 'Plot centered tracks');
    
    %% Setup the status bar.
    hStatus = statusbar(hCenteredTracks, '');
    hStatus.CornerGrip.setVisible(false)
    
    hStatus.ProgressBar.setForeground(java.awt.Color.black)
    hStatus.ProgressBar.setString('')
    hStatus.ProgressBar.setStringPainted(true)
    
    %% Add the GUI to the base's GUI children.
    guiChildren = getappdata(hSortomizerBase, 'guiChildren');
    guiChildren = [guiChildren; hCenteredTracks];
    setappdata(hSortomizerBase, 'guiChildren', guiChildren)
    
    %% Nested function to plot zero-centered tracks.
    function pushplot(varargin)
        % PUSHPLOT Plot selected object tracks centered at [0, 0, 0].
        %
        %
        
        %% Get the selected object.
        plotObjectIdx = get(popupObjects, 'Value');
        xObject = surpassObjects(plotObjectIdx).ImarisObject;

        %% Get the Surpass object data.
        if xImarisApp.GetFactory.IsSpots(xObject)
            % Get the spot positions.
            objectPos = xObject.GetPositionsXYZ;

        else
            % Get the number of surfaces.
            surfaceCount = xObject.GetNumberOfSurfaces;

            % Get the surface positions and times.
            objectPos = zeros(surfaceCount, 3);
            for s = 1:surfaceCount
                objectPos(s, :) = xObject.GetCenterOfMass(s - 1);
            end % s

        end % if

        %% Allocate an array to collect all the recentered positions.
        centeredPos = zeros(size(objectPos));

        %% Get the track information.
        trackIDs = xObject.GetTrackIds;
        trackEdges = xObject.GetTrackEdges;
        trackLabels = unique(trackIDs);

        %% Create a figure for plotting.
        hGraphFig = figure(...
            'CloseRequestFcn', {@hfigclosereqfcn}, ...
            'Color', bColor, ...
            'Name', [char(xObject.GetName) ' tracks'], ...
            'NumberTitle', 'off', ...
            'Tag', 'hGraphFig');
        
        axColor = 0.5*ones(3, 1);
        hAxes = axes(...
            'Color', bColor, ...
            'FontSize', 12, ...
            'Linewidth', 2, ...
            'Parent', hGraphFig, ...
            'TickDir', 'out', ...
            'XColor', axColor, ...
            'YColor', axColor, ...
            'ZColor', axColor);
                
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

            % Add the centered coordinates to the list of all track positions.
            centeredPos(rSpots + 1, :) = cPos;

            % Plot the shifted track.
            line(cPos(:, 1), cPos(:, 2), cPos(:, 3), ...
                'Color', lineColors(r, :), ...
                'LineWidth', 2, ...
                'Parent', hAxes) 

            % Update the waitbar.
            hStatus.ProgressBar.setValue(r)
        end % for r
        
        % Reset the status bar.
        hStatus.setText('')
        hStatus.ProgressBar.setValue(0)
        hStatus.ProgressBar.setVisible(false)
        
        %% Format the axes.
        axis(hAxes, 'equal')
        
        % Make the axes symmetric about zero.
        % For x:
        xRange = xlim(hAxes);
        xExtreme = max(abs(xRange));
        xlim(hAxes, [-xExtreme xExtreme])
        
        % For y:
        yRange = ylim(hAxes);
        yExtreme = max(abs(yRange));
        ylim(hAxes, [-yExtreme yExtreme])
        
        % For z:
        zRange = zlim(hAxes);
        zExtreme = max(abs(zRange));
        zlim(hAxes, [-zExtreme zExtreme])
        
        %% Add lines to serve as coordinate axes.
        xAx = line(xlim, [0 0], [0 0], 'Color', axColor, 'LineStyle', ':', 'LineWidth', 2);
        yAx = line([0 0], ylim, [0 0], 'Color', axColor, 'LineStyle', ':', 'LineWidth', 2);
        zAx = line([0 0], [0 0], zlim, 'Color', axColor, 'LineStyle', ':', 'LineWidth', 2);
        
        uistack(xAx, 'bottom')
        uistack(yAx, 'bottom')
        uistack(zAx, 'bottom')
        
        %% Label the axes with the Imaris units.
        imarisUnits = char(xImarisApp.GetDataSet.GetUnit);
        
        % If the units are in microns, add a slash for latex. I think Imaris
        % always uses microns, but just in case.
        if strcmp(imarisUnits, 'um')
            imarisUnits = '\mum';
        end % if
        
        xlabel(['x (' imarisUnits ')'], 'Color', axColor)
        ylabel(['y (' imarisUnits ')'], 'Color', axColor)
        zlabel(['z (' imarisUnits ')'], 'Color', axColor)
        
        %% Add a menu with choices for doing axes adjustments.
        % Create the menu.    
        menuAaxes = uimenu(hGraphFig, 'Label', 'Axes');
        
        % Create the axes limit adjustment menu option.
        uimenu(menuAaxes, ...
            'Callback', {@setaxeslimits}, ...
            'Label', 'Adjust limits', ...
            'Tag', 'menuItemAxesLimit');
        
        % Create the view (rotations) adjustment menu option.
        uimenu(menuAaxes, ...
            'Callback', {@setaxesview}, ...
            'Label', 'Adjust view', ...
            'Tag', 'menuItemAxesAngle');
        
        %% Add the graph figure to the base's graph children.
        graphChildren = getappdata(hSortomizerBase, 'graphChildren');
        graphChildren = [graphChildren; hGraphFig];
        setappdata(hSortomizerBase, 'graphChildren', graphChildren)
        
        %% Axes adjustment functions
        function setaxeslimits(varargin)
            %
            %
            %
            
            %% Check for an existing limit adjustment figure.
            hLimits = getappdata(hGraphFig, 'hLimits');

            % If the adjustment window exists, raise it and return.
            if ~isempty(hLimits)
                figure(hLimits)
                return
            end

            %% Create the adjustment figure.
            hFigPos = get(hGraphFig, 'Position');

            limitsWidth = 230;
            limitsHeight = 187;
            hLimitsPos = [hFigPos(1) + hFigPos(3)/2 - limitsWidth/2, ...
                hFigPos(2) + hFigPos(4)/2 - limitsHeight/2, ...
                limitsWidth, ...
                limitsHeight];
                
            % Create the figure.
            hLimits = figure(...
                'Color', bColor, ...
                'CloseRequestFcn', {@hlimitsclosereqfcn, hGraphFig}, ...
                'MenuBar', 'none', ...
                'Name', 'Adjust axes limits', ...
                'NumberTitle', 'off', ...
                'Position', hLimitsPos, ...
                'Resize', 'off', ...
                'Tag', 'hLimits');

            %% Create the labels.
            uicontrol(...
                'Background', bColor, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'Parent', hLimits, ...
                'Position', [70 144 60 24], ...
                'String', 'Minimum', ...
                'Style', 'text', ...
                'Tag', 'textMinimum');

            uicontrol(...
                'Background', bColor, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'Parent', hLimits, ...
                'Position', [160 144 60 24], ...
                'String', 'Maximum', ...
                'Style', 'text', ...
                'Tag', 'textMaximum');
            
            %% Create the adjustment edit boxes.
            % X adjustment boxes:
            uicontrol(...
                'Background', bColor, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'HorizontalAlign', 'Left', ...
                'Parent', hLimits, ...
                'Position', [10 116 50 24], ...
                'String', 'X Range', ...
                'Style', 'text', ...
                'Tag', 'textXRange');
            
            xInitial = get(hAxes, 'XLim');
            editXMin = uicontrol(...
                'Background', bColor, ...
                'Callback', @setxlim, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'Parent', hLimits, ...
                'Position', [75 120 50 24], ...
                'String', xInitial(1), ...
                'Style', 'edit', ...
                'Tag', 'editXMin');

            editXMax = uicontrol(...
                'Background', bColor, ...
                'Callback', @setxlim, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'Parent', hLimits, ...
                'Position', [165 120 50 24], ...
                'String', xInitial(2), ...
                'Style', 'edit', ...
                'Tag', 'editXMax');

            % Y adjustment boxes:
            uicontrol(...
                'Background', bColor, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'HorizontalAlign', 'Left', ...
                'Parent', hLimits, ...
                'Position', [10 66 50 24], ...
                'String', 'Y Range', ...
                'Style', 'text', ...
                'Tag', 'textYRange');
            
            yInitial = get(hAxes, 'XLim');
            editYMin = uicontrol(...
                'Background', bColor, ...
                'Callback', @setylim, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'Parent', hLimits, ...
                'Position', [75 70 50 24], ...
                'String', yInitial(1), ...
                'Style', 'edit', ...
                'Tag', 'editYMin');

            editYMax = uicontrol(...
                'Background', bColor, ...
                'Callback', @setylim, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'Parent', hLimits, ...
                'Position', [165 70 50 24], ...
                'String', yInitial(2), ...
                'Style', 'edit', ...
                'Tag', 'editYMax');

            % Z adjustment boxes:
            uicontrol(...
                'Background', bColor, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'HorizontalAlign', 'Left', ...
                'Position', [10 16 50 24], ...
                'Parent', hLimits, ...
                'String', 'Z Range', ...
                'Style', 'text', ...
                'Tag', 'textZRange');
            
            zInitial = get(hAxes, 'XLim');
            editZMin = uicontrol(...
                'Background', bColor, ...
                'Callback', @setzlim, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'Parent', hLimits, ...
                'Position', [75 20 50 24], ...
                'String', zInitial(1), ...
                'Style', 'edit', ...
                'Tag', 'editZMin');

            editZMax = uicontrol(...
                'Background', bColor, ...
                'Callback', @setzlim, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'Parent', hLimits, ...
                'Position', [165 20 50 24], ...
                'String', zInitial(2), ...
                'Style', 'edit', ...
                'Tag', 'editZMax');

            %% Store the adjustment figure's handle in the appdata of the main figure.
            setappdata(hGraphFig, 'hLimits', hLimits)

            %% Attach listeners to the axes to update the limits on a limit change.
            addlistener(hAxes, 'XLim', 'PostSet', ...
                @(hSrc, eventData)limitsync(hSrc, eventData, editXMin, editXMax));
            addlistener(hAxes, 'YLim', 'PostSet', ...
                @(hSrc, eventData)limitsync(hSrc, eventData, editYMin, editYMax));
            addlistener(hAxes, 'ZLim', 'PostSet', ...
                @(hSrc, eventData)limitsync(hSrc, eventData, editZMin, editZMax));

            %% Nested functions for axes limit adjustments
            function setxlim(varargin)
                %% Get the current x limits.
                currentXLim = get(hAxes, 'XLim');

                %% Get the desired range.
                xMin = str2double(get(editXMin, 'String'));
                xMax = str2double(get(editXMax, 'String'));

                %% Test for a valid range, then update or reset.
                if any(isnan([xMin, xMax])) || xMin >= xMax
                    % Reset the x editbox values.
                    set(editXMin, 'String', currentXLim(1))
                    set(editXMax, 'String', currentXLim(2))

                else
                    % Update the axes range.
                    set(hAxes, 'XLim', [xMin xMax])

                    % Update the xdata for the x axes center line.
                    set(xAx, 'XData', [xMin xMax])

                end % if
            end % setxlim

            function setylim(varargin)
                %% Get the current y limits.
                currentYLim = get(hAxes, 'YLim');

                %% Get the desired range.
                yMin = str2double(get(editYMin, 'String'));
                yMax = str2double(get(editYMax, 'String'));

                %% Test for a valid range, then update or reset.
                if any(isnan([yMin, yMax])) || yMin >= yMax
                    % Reset the y editbox values.
                    set(editYMin, 'String', currentYLim(1))
                    set(editYMax, 'String', currentYLim(2))

                else
                    % Update the axes range.
                    set(hAxes, 'YLim', [yMin yMax])

                    % Update the xdata for the x axes center line.
                    set(yAx, 'YData', [yMin yMax])

                end % if
            end % setylim

            function setzlim(varargin)
                %% Get the current z limits.
                currentZLim = get(hAxes, 'ZLim');

                %% Get the desired range.
                zMin = str2double(get(editZMin, 'String'));
                zMax = str2double(get(editZMax, 'String'));

                %% Test for a valid range, then update or reset.
                if any(isnan([zMin, zMax])) || zMin >= zMax
                    % Reset the z editbox values.
                    set(editZMin, 'String', currentZLim(1))
                    set(editZMax, 'String', currentZLim(2))

                else
                    % Update the axes range.
                    set(hAxes, 'ZLim', [zMin zMax])

                    % Update the xdata for the x axes center line.
                    set(zAx, 'ZData', [zMin zMax])

                end % if
            end % setzlim
        end % setaxeslimits

        function setaxesview(varargin)

            %% Check for an existing view adjustment figure.
            hView = getappdata(hGraphFig, 'hView');

            % If the adjustment window exists, raise it and return.
            if ~isempty(hView)
                figure(hView)
                return
            end

            %% Create the adjustment figure.
            hFigPos = get(hGraphFig, 'Position');

            viewWidth = 135;
            viewHeight = 137;
            hViewPos = [hFigPos(1) + hFigPos(3)/2 - viewWidth/2, ...
                hFigPos(2) + hFigPos(4)/2 - viewHeight/2, ...
                viewWidth, ...
                viewHeight];

            % Create the view adjustment figure.
            hView = figure(...
                'CloseRequestFcn', {@hviewclosereqfcn, hGraphFig}, ...
                'Color', bColor, ...
                'MenuBar', 'none', ...
                'Name', 'Adjust axes view', ...
                'NumberTitle', 'off', ...
                'Position', hViewPos, ...
                'Resize', 'off', ...
                'Tag', 'hView');

            %% Create the degrees value label.
            uicontrol(...
                'Background', bColor, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'HorizontalAlign', 'Center', ...
                'Parent', hView, ...
                'Position', [73 94 50 24], ...
                'String', 'Degrees', ...
                'Style', 'text', ...
                'Tag', 'textDegrees');

            %% Create the view adjustment edit boxes.
            % Get the initial view.
            viewInitial = get(hAxes, 'View');

            % Azimuth adjustment box:
            uicontrol(...
                'Background', bColor, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'HorizontalAlign', 'Left', ...
                'Parent', hView, ...
                'Position', [10 66 60 24], ...
                'String', 'Azimuth', ...
                'Style', 'text', ...
                'Tag', 'textAzimuth');

            editAzimuth = uicontrol('Style', 'edit', ...
                'Background', bColor, ...
                'Callback', @setazimuth, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'Parent', hView, ...
                'Position', [75 70 48 24], ...
                'String', viewInitial(1), ...
                'Tag', 'editAzimuth');

            % Elevation adjustment box:
            uicontrol(...
                'Background', bColor, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'HorizontalAlign', 'Left', ...
                'Parent', hView, ...
                'Position', [10 16 60 24], ...
                'String', 'Elevation', ...
                'Style', 'text', ...
                'Tag', 'textElevation');

            editElevation = uicontrol('Style', 'edit', ...
                'Background', bColor, ...
                'Callback', @setelevation, ...
                'FontSize', 10, ...
                'Foreground', fColor, ...
                'Parent', hView, ...
                'Position', [75 20 50 24], ...
                'String', viewInitial(2), ...
                'Tag', 'editElevation');

            %% Store the adjustment figure's handle in the appdata of the main figure.
            setappdata(hGraphFig, 'hView', hView)

            %% Attach a listener to the axes to update the azimuth and elevation on a view change.
            addlistener(hAxes, 'View', 'PostSet', ...
                @(hSrc, eventData)viewsync(hSrc, eventData, editAzimuth, editElevation));
            
            %% Nested functions for axes limit adjustments
            function setazimuth(varargin)
                %
                %
                %
                
                %% Get the current axes x limits.
                currentView = get(hAxes, 'View');

                %% Get the desired azimuth value.
                azValue = str2double(get(editAzimuth, 'String'));

                %% Test for a valid value, then update or reset.
                if ~isreal(azValue)
                    % Reset the azimuth editbox value.
                    set(editAzimuth, 'String', currentView(1))

                else
                    % Update the axes view.
                    set(hAxes, 'View', [azValue currentView(2)])

                end % if
            end % azimuthchange

            function setelevation(varargin)
                %
                %
                %
                
                %% Get the current axes x limits.
                currentView = get(hAxes, 'View');

                %% Get the elevation value.
                elValue = str2double(get(editElevation, 'String'));

                %% Test for a valid range, then update or reset.
                if ~isreal(elValue)
                    % Reset the elevation editbox value.
                    set(editElevation, 'String', currentView(2))

                else
                    % Update the axes view.
                    set(hAxes, 'View', [currentView(1) elValue])

                end % if

            end % elevationchange
        end % setaxesview

        %% Sync functions for the adjustment figures
        function limitsync(~, eventData, editMin, editMax)
            %
            %
            %

            if ishandle(editMin)
                %% Get the limits.
                limitValue = eventData.NewValue;

                %% Set the edit min and max boxes.
                set(editMin, 'String', limitValue(1))
                set(editMax, 'String', limitValue(2))
                
                %% Update the axis line.
                switch get(editMin, 'Tag')
                    
                    case 'editXMin'
                        set(xAx, 'XData', limitValue)
                        
                    case 'editYMin'
                        set(yAx, 'YData', limitValue)
                        
                    case 'editZMin'
                        set(zAx, 'ZData', limitValue)                        
                        
                end % switch
            end % if
        end % limitsync
        
        function viewsync(~, eventData, editAzimuth, editElevation)
            %
            %
            %

            if ishandle(editAzimuth)
                %% Get the view.
                viewValue = eventData.NewValue;

                %% Set the azimuth and elevation edit boxes.
                set(editAzimuth, 'String', viewValue(1))
                set(editElevation, 'String', viewValue(2))
            end % if
        end % viewsync

        %% Close request functions
        function hfigclosereqfcn(hGraphFig, ~)
            %
            %
            %
            
            %% Check for associated axes adjustment figures.
            hLimits = getappdata(hGraphFig, 'hLimits');
            hView = getappdata(hGraphFig, 'hView');

            %% Delete any adjustment figures.
            if ~isempty(hLimits)
                delete(hLimits)
            end % if

            if ~isempty(hView)
                delete(hView)
            end % if
            
            %% Delete the figure.
            delete(hGraphFig)
        end % hfigclosereqfcn

        function hlimitsclosereqfcn(hLimits, ~, hFig)
            %
            %
            %
            
            %% Remove the adjustment figure handle from the main figure's appdata.
            rmappdata(hFig, 'hLimits')

            %% Delete the limits adjustment figure.
            delete(hLimits)
        end % hlimitsfigclosereqfcn

        function hviewclosereqfcn(hView, ~, hFig)
            %
            %
            %
            
            %% Remove the adjustment figure handle from the main figure's appdata.
            rmappdata(hFig, 'hView')

            %% Delete the view adjustment figure.
            delete(hView)

        end % hviewfigclosereqfcn
    end % pushplot    
end % sortomizercenteredtracks


function closerequestfcn(hObject, ~, hSortomizerBase)
    % Close sortomizer sub-GUIs
    %
    %
    
    %% Remove any open graph handles from the base's appdata and delete.
    % Find any open centered plot graphs.
    graphChildren = getappdata(hSortomizerBase, 'graphChildren');
    centeredPlotIdxs = find(strcmp(get(graphChildren, 'Tag'), 'hGraphFig'));

    % Delete the graphs and any adjustment windows that are open.
    for c = centeredPlotIdxs'
        hLimitsFig = getappdata(graphChildren(c), 'hLimitsFig');
        if ~isempty(hLimitsFig)
            delete(hLimitsFig)
        end % if

        hViewFig = getappdata(graphChildren(c), 'hViewFig');
        if ~isempty(hViewFig)
            delete(hViewFig)
        end % if
    end % for p

    delete(graphChildren(centeredPlotIdxs))
    graphChildren(centeredPlotIdxs) = [];
    setappdata(hSortomizerBase, 'graphChildren', graphChildren)

    %% Remove the GUI's handle from the base's appdata and delete.
    guiChildren = getappdata(hSortomizerBase, 'guiChildren');

    guiIdx = guiChildren == hObject;
    guiChildren = guiChildren(~guiIdx);
    setappdata(hSortomizerBase, 'guiChildren', guiChildren)
    delete(hObject);
end % closerequestfcn