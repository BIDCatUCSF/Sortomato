function [graphTracks, axesGraph] = sortomatocenteredtracksgraph(guiCenteredTracks, xObject, guiSortomato)
    % SORTOMATOCENTEREDTRACKSGRAPH Create and prepare a centered plot figure window
    %   Detailed explanation goes here
    
    %% Set the figure and font colors.
    if all(get(guiCenteredTracks, 'Color') == [0 0 0])
        sortomatocenteredtracksgraphCData = load('sortomatocenteredtracksgraphK_cdata.mat');
        
        bColor = 'k';
        bColorJava = java.awt.Color.black;
        fColor = 'w';
        
        axColor = 0.75*ones(3, 1);
        
    else
        sortomatocenteredtracksgraphCData = load('sortomatocenteredtracksgraph_cdata.mat');
        
        bColor = 'w';
        bColorJava = java.awt.Color.white;
        fColor = 'k';
        
        axColor = 0.25*ones(3, 1);
        
    end % if
    
    %% Create the figure.
    parentPos = get(guiCenteredTracks, 'Position');
    
    guiWidth = 560;
    guiHeight = 420;
    guiPos = [...
        parentPos(1, 1) + 25, ...
        parentPos(1, 2) + parentPos(1, 4) - guiHeight - 50, ...
        guiWidth, ...
        guiHeight]; 
    
    graphTracks = figure(...
        'CloseRequestFcn', {@closerequestfcn, guiSortomato}, ...
        'Color', bColor, ...
        'DockControls', 'off', ...
        'InvertHardCopy', 'off', ...
        'MenuBar', 'None', ...
        'Name', [char(xObject.GetName) ' tracks'], ...
        'NumberTitle', 'off', ...
        'PaperPositionMode', 'auto', ...
        'Position', guiPos, ...
        'Renderer', 'ZBuffer', ...
        'Tag', 'graphTracks');
    
    axesGraph = axes(...
        'Color', 'None', ...
        'FontSize', 12, ...
        'Linewidth', 2, ...
        'Parent', graphTracks, ...
        'Tag', 'axesGraph', ...
        'TickDir', 'out', ...
        'XColor', axColor, ...
        'YColor', axColor, ...
        'ZColor', axColor);

        %% Add lines to serve as coordinate axes.
        xAx = line(xlim, [0 0], [0 0], ...
            'Color', axColor, ...
            'DisplayName', 'X', ...
            'LineStyle', ':', ...
            'LineWidth', 2, ...
            'Parent', gca);
        yAx = line([0 0], ylim, [0 0], ...
            'Color', axColor, ...
            'DisplayName', 'Y', ...
            'LineStyle', ':', ...
            'LineWidth', 2, ...
            'Parent', gca);
        zAx = line([0 0], [0 0], zlim, ...
            'Color', axColor, ...
            'DisplayName', 'Z', ...
            'LineStyle', ':', ...
            'LineWidth', 2, ...
            'Parent', gca);
        
        uistack([zAx, yAx, xAx], 'bottom')
        
    %% Label the axes with the Imaris units.
    xImarisApp = getappdata(guiSortomato, 'xImarisApp');
    imarisUnits = char(xImarisApp.GetDataSet.GetUnit);

    % If the units are in microns, add a slash for latex. I think Imaris
    % always uses microns, but just in case.
    if strcmp(imarisUnits, 'um') || isempty(imarisUnits)
        imarisUnits = '\mum';
    end % if

    xlabel(['x (' imarisUnits ')'], 'Color', axColor)
    ylabel(['y (' imarisUnits ')'], 'Color', axColor)
    zlabel(['z (' imarisUnits ')'], 'Color', axColor)

    %% Attach listeners to the axes to update the coordinate axes lines on a limit change.
    addlistener(axesGraph, 'XLim', 'PostSet', ...
        @(propLimit, eventData)coordsync(propLimit, eventData));
    addlistener(axesGraph, 'YLim', 'PostSet', ...
        @(propLimit, eventData)coordsync(propLimit, eventData));
    addlistener(axesGraph, 'ZLim', 'PostSet', ...
        @(propLimit, eventData)coordsync(propLimit, eventData));
        
    %% Create the toolbar and toolbar buttons.
    toolbarGraph = uitoolbar(graphTracks, ...
        'Tag', 'toolbarGraphTracks');

    % Create the toolbar buttons.
    uitoggletool(toolbarGraph, ...
        'CData', sortomatocenteredtracksgraphCData.DataCursor, ...
        'ClickedCallback', {@toggledatacursorcallback, graphTracks}, ...
        'Tag', 'toggleDataCursor', ...
        'TooltipString', 'Activate the data cursor')
    
    uitoggletool(toolbarGraph, ...
        'CData', sortomatocenteredtracksgraphCData.Zoom, ...
        'ClickedCallback', {@togglezoomcallback, graphTracks}, ...
        'Tag', 'toggleZoom', ...
        'TooltipString', 'Activate zooming')
    
    uitoggletool(toolbarGraph, ...
        'CData', sortomatocenteredtracksgraphCData.Pan, ...
        'ClickedCallback', {@togglepancallback, graphTracks}, ...
        'Tag', 'togglePan', ...
        'TooltipString', 'Activate panning')
    
    uitoggletool(toolbarGraph, ...
        'CData', sortomatocenteredtracksgraphCData.Rotate3D, ...
        'ClickedCallback', {@togglerotatecallback, graphTracks}, ...
        'Tag', 'toggleRotate', ...
        'TooltipString', 'Activate rotation')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatocenteredtracksgraphCData.ManualLimits, ...
        'ClickedCallback', {@pushmanuallimitscallback}, ...
        'Separator', 'on', ...
        'Tag', 'pushManualLimits', ...
        'TooltipString', 'Set axes limits')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatocenteredtracksgraphCData.ManualView, ...
        'ClickedCallback', {@setaxesview}, ...
        'Tag', 'pushAxesView', ...
        'TooltipString', 'Set axes view')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatocenteredtracksgraphCData.GraphExport, ...
        'ClickedCallback', {@sortomatographpushgraphexport, graphTracks}, ...
        'Separator', 'on', ...
        'Tag', 'pushGraphExport', ...
        'TooltipString', 'Export the current graph')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatocenteredtracksgraphCData.GraphDataExport, ...
        'ClickedCallback', {@sortomatographpushdataexport, graphTracks}, ...
        'Tag', 'pushGraphDataExport', ...
        'TooltipString', 'Export the current graph data')
    
    %% Set the toobar and button backgrounds.
    % Get the underlying JToolBar component.
    drawnow
    jToolbar = get(get(toolbarGraph, 'JavaContainer'), 'ComponentPeer');
    
    % Set the toolbar background color.
    jToolbar.setBackground(bColorJava);
    jToolbar.getParent.getParent.setBackground(bColorJava);
    
    % Set the toolbar components' background color.
    jtbComponents = jToolbar.getComponents;
    for t = 1:length(jtbComponents)
        jtbComponents(t).setOpaque(false);
        jtbComponents(t).setBackground(bColorJava);
    end % for t
    
    % Set the toolbar more icon to a custom icon that matches the figure color.
    javaImage = im2java(sortomatocenteredtracksgraphCData.MoreToolbar);
    javaIcon = javax.swing.ImageIcon(javaImage);
    jtbComponents(1).setIcon(javaIcon)
    jtbComponents(1).setToolTipText('More tools')
                
    %% Add the figure to the base's graph children.
    graphChildren = getappdata(guiSortomato, 'graphChildren');
    graphChildren = [graphChildren; graphTracks];
    setappdata(guiSortomato, 'graphChildren', graphChildren)

    %% Store the XT objects and data associated with the figure.
    setappdata(graphTracks, 'guiSortomato', guiSortomato)
    setappdata(graphTracks, 'xObject', xObject)
    xImarisApp = getappdata(guiSortomato, 'xImarisApp');
    setappdata(graphTracks, 'xImarisApp', xImarisApp)

    %% Nested axes adjustment functions
    function pushmanuallimitscallback(varargin)
        % PUSHMANUALLIMITSCALLBACK Adjust the axes limits
        %
        %

        %% Check for an existing limit adjustment figure.
        guiLimits = getappdata(graphTracks, 'guiLimits');

        % If the adjustment window exists, raise it and return.
        if ~isempty(guiLimits)
            figure(guiLimits)
            return
        end

        %% Create the adjustment figure.
        graphPos = get(graphTracks, 'Position');

        limitsWidth = 230;
        limitsHeight = 187;
        guiLimitsPos = [graphPos(1) + graphPos(3)/2 - limitsWidth/2, ...
            graphPos(2) + graphPos(4)/2 - limitsHeight/2, ...
            limitsWidth, ...
            limitsHeight];

        % Create the figure.
        guiLimits = figure(...
            'Color', bColor, ...
            'CloseRequestFcn', {@guilimitsclosereqfcn, graphTracks}, ...
            'MenuBar', 'none', ...
            'Name', 'Adjust axes limits', ...
            'NumberTitle', 'off', ...
            'Position', guiLimitsPos, ...
            'Resize', 'off', ...
            'Tag', 'guiLimits');

        %% Create the labels.
        uicontrol(...
            'Background', bColor, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'Parent', guiLimits, ...
            'Position', [70 144 60 24], ...
            'String', 'Minimum', ...
            'Style', 'text', ...
            'Tag', 'textMinimum');

        uicontrol(...
            'Background', bColor, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'Parent', guiLimits, ...
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
            'Parent', guiLimits, ...
            'Position', [10 116 50 24], ...
            'String', 'X Range', ...
            'Style', 'text', ...
            'Tag', 'textXRange');

        xInitial = get(axesGraph, 'XLim');
        editXMin = uicontrol(...
            'Background', bColor, ...
            'Callback', @editxlimcallback, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'KeyPressFcn', @editxminkeypresscallback, ...
            'Parent', guiLimits, ...
            'Position', [75 120 50 24], ...
            'String', xInitial(1), ...
            'Style', 'edit', ...
            'Tag', 'editXMin');

        editXMax = uicontrol(...
            'Background', bColor, ...
            'Callback', @editxlimcallback, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'KeyPressFcn', @editxmaxkeypresscallback, ...
            'Parent', guiLimits, ...
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
            'Parent', guiLimits, ...
            'Position', [10 66 50 24], ...
            'String', 'Y Range', ...
            'Style', 'text', ...
            'Tag', 'textYRange');

        yInitial = get(axesGraph, 'XLim');
        editYMin = uicontrol(...
            'Background', bColor, ...
            'Callback', @editylimcallback, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'KeyPressFcn', @edityminkeypresscallback, ...
            'Parent', guiLimits, ...
            'Position', [75 70 50 24], ...
            'String', yInitial(1), ...
            'Style', 'edit', ...
            'Tag', 'editYMin');

        editYMax = uicontrol(...
            'Background', bColor, ...
            'Callback', @editylimcallback, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'KeyPressFcn', @editymaxkeypresscallback, ...
            'Parent', guiLimits, ...
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
            'Parent', guiLimits, ...
            'String', 'Z Range', ...
            'Style', 'text', ...
            'Tag', 'textZRange');

        zInitial = get(axesGraph, 'XLim');
        editZMin = uicontrol(...
            'Background', bColor, ...
            'Callback', @editzlimcallback, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'KeyPressFcn', @editzminkeypresscallback, ...
            'Parent', guiLimits, ...
            'Position', [75 20 50 24], ...
            'String', zInitial(1), ...
            'Style', 'edit', ...
            'Tag', 'editZMin');

        editZMax = uicontrol(...
            'Background', bColor, ...
            'Callback', @editzlimcallback, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'KeyPressFcn', @editzmaxkeypresscallback, ...
            'Parent', guiLimits, ...
            'Position', [165 20 50 24], ...
            'String', zInitial(2), ...
            'Style', 'edit', ...
            'Tag', 'editZMax');

        %% Store the adjustment figure's handle in the appdata of the main figure.
        setappdata(graphTracks, 'guiLimits', guiLimits)

        %% Attach listeners to the axes to update the edit box values on a limit change.
        addlistener(axesGraph, 'XLim', 'PostSet', ...
            @(hSrc, eventData)limitsync(hSrc, eventData, editXMin, editXMax));
        addlistener(axesGraph, 'YLim', 'PostSet', ...
            @(hSrc, eventData)limitsync(hSrc, eventData, editYMin, editYMax));
        addlistener(axesGraph, 'ZLim', 'PostSet', ...
            @(hSrc, eventData)limitsync(hSrc, eventData, editZMin, editZMax));

        %% Nested functions for axes limit adjustments
        function editxlimcallback(varargin)
            % EDITXLIMCALLBACK
            %
            %
            
            %% Get the current x limits.
            currentXLim = get(axesGraph, 'XLim');

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
                set(axesGraph, 'XLim', [xMin xMax])

            end % if
        end % editxlimcallback

        function editylimcallback(varargin)
            % EDITYLIMCALLBACK
            %
            %
            
            %% Get the current y limits.
            currentYLim = get(axesGraph, 'YLim');

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
                set(axesGraph, 'YLim', [yMin yMax])

            end % if
        end % editylimcallback

        function editzlimcallback(varargin)
            % EDITZLIMCALLBACK
            %
            %
            
            %% Get the current z limits.
            currentZLim = get(axesGraph, 'ZLim');

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
                set(axesGraph, 'ZLim', [zMin zMax])

            end % if
        end % editzlimcallback

        function editxminkeypresscallback(varargin)
            % EDITXMINKEYPRESSCALLBACK Update the axes x min on up or down arrow
            %
            %

            %% Check for an up or down press.
            switch varargin{2}.Key

                case 'uparrow'
                    xLim = get(gca, 'XLim');
                    xLim(1) = xLim(1) + 1;

                case 'downarrow'
                    xLim = get(gca, 'XLim');
                    xLim(1) = xLim(1) - 1;

                otherwise
                    return

            end % switch

            %% Test for a valid range, and update the axes and editbox.
            if xLim(1) >= xLim(2)
                return
            end % if

            set(editXMin, 'String', xLim(1))
            set(gca, 'XLim', xLim)
        end % editzminkeypresscallback

        function editxmaxkeypresscallback(varargin)
            % EDITXMAXKEYPRESSCALLBACK Update the axes x max on up or down arrow
            %
            %

            %% Check for an up or down press.
            switch varargin{2}.Key

                case 'uparrow'
                    xLim = get(gca, 'XLim');
                    xLim(2) = xLim(2) + 1;

                case 'downarrow'
                    xLim = get(gca, 'XLim');
                    xLim(2) = xLim(2) - 1;

                otherwise
                    return

            end % switch

            %% Test for a valid range, and update the axes and editbox.
            if xLim(1) >= xLim(2)
                return
            end % if

            set(editXMax, 'String', xLim(2))
            set(gca, 'XLim', xLim)
        end % editxmaxkeypresscallback

        function edityminkeypresscallback(varargin)
            % EDITYMINKEYPRESSCALLBACK Update the axes y min on up or down arrow
            %
            %

            %% Check for an up or down press.
            switch varargin{2}.Key

                case 'uparrow'
                    yLim = get(gca, 'YLim');
                    yLim(1) = yLim(1) + 1;

                case 'downarrow'
                    yLim = get(gca, 'YLim');
                    yLim(1) = yLim(1) - 1;

                otherwise
                    return

            end % switch

            %% Test for a valid range, and update the axes and editbox.
            if yLim(1) >= yLim(2)
                return
            end % if

            set(editYMin, 'String', yLim(1))
            set(gca, 'YLim', yLim)
        end % editxminkeypresscallback

        function editymaxkeypresscallback(varargin)
            % EDITYMAXKEYPRESSCALLBACK Update the axes y max on up or down arrow
            %
            %

            %% Check for an up or down press.
            switch varargin{2}.Key

                case 'uparrow'
                    yLim = get(gca, 'YLim');
                    yLim(2) = yLim(2) + 1;

                case 'downarrow'
                    yLim = get(gca, 'YLim');
                    yLim(2) = yLim(2) - 1;

                otherwise
                    return

            end % switch

            %% Test for a valid range, and update the axes and editbox.
            if yLim(1) >= yLim(2)
                return
            end % if

            set(editYMax, 'String', yLim(2))
            set(gca, 'YLim', yLim)
        end % editxmaxkeypresscallback

        function editzminkeypresscallback(varargin)
            % EDITZMINKEYPRESSCALLBACK Update the axes z min on up or down arrow
            %
            %

            %% Check for an up or down press.
            switch varargin{2}.Key

                case 'uparrow'
                    zLim = get(gca, 'ZLim');
                    zLim(1) = zLim(1) + 1;

                case 'downarrow'
                    zLim = get(gca, 'ZLim');
                    zLim(1) = zLim(1) - 1;

                otherwise
                    return

            end % switch

            %% Test for a valid range, and update the axes and editbox.
            if zLim(1) >= zLim(2)
                return
            end % if

            set(editZMin, 'String', zLim(1))
            set(gca, 'ZLim', zLim)
        end % editzminkeypresscallback

        function editzmaxkeypresscallback(varargin)
            % EDITZMAXKEYPRESSCALLBACK Update the axes z max on up or down arrow
            %
            %

            %% Check for an up or down press.
            switch varargin{2}.Key

                case 'uparrow'
                    zLim = get(gca, 'ZLim');
                    zLim(2) = zLim(2) + 1;

                case 'downarrow'
                    zLim = get(gca, 'ZLim');
                    zLim(2) = zLim(2) - 1;

                otherwise
                    return

            end % switch

            %% Test for a valid range, and update the axes and editbox.
            if zLim(1) >= zLim(2)
                return
            end % if

            set(editZMax, 'String', zLim(2))
            set(gca, 'ZLim', zLim)
        end % editzmaxkeypresscallback
    end % setaxeslimits

    function setaxesview(varargin)
        %
        %
        %

        %% Check for an existing view adjustment figure.
        guiView = getappdata(graphTracks, 'guiView');

        % If the adjustment window exists, raise it and return.
        if ~isempty(guiView)
            figure(guiView)
            return
        end

        %% Create the adjustment figure.
        hFigPos = get(graphTracks, 'Position');

        viewWidth = 135;
        viewHeight = 137;
        guiViewPos = [hFigPos(1) + hFigPos(3)/2 - viewWidth/2, ...
            hFigPos(2) + hFigPos(4)/2 - viewHeight/2, ...
            viewWidth, ...
            viewHeight];

        % Create the view adjustment figure.
        guiView = figure(...
            'CloseRequestFcn', {@guiviewclosereqfcn, graphTracks}, ...
            'Color', bColor, ...
            'MenuBar', 'none', ...
            'Name', 'Adjust axes view', ...
            'NumberTitle', 'off', ...
            'Position', guiViewPos, ...
            'Resize', 'off', ...
            'Tag', 'guiView');

        %% Create the degrees value label.
        uicontrol(...
            'Background', bColor, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'HorizontalAlign', 'Center', ...
            'Parent', guiView, ...
            'Position', [73 94 50 24], ...
            'String', 'Degrees', ...
            'Style', 'text', ...
            'Tag', 'textDegrees');

        %% Create the view adjustment edit boxes.
        % Get the initial view.
        viewInitial = get(axesGraph, 'View');

        % Azimuth adjustment box:
        uicontrol(...
            'Background', bColor, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'HorizontalAlign', 'Left', ...
            'Parent', guiView, ...
            'Position', [10 66 60 24], ...
            'String', 'Azimuth', ...
            'Style', 'text', ...
            'Tag', 'textAzimuth');

        editAzimuth = uicontrol( ...
            'Background', bColor, ...
            'Callback', @editazimuthcallback, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'KeyPressFcn', @editazimuthkeypresscallback, ...
            'Parent', guiView, ...
            'Position', [75 70 48 24], ...
            'String', viewInitial(1), ...
            'Style', 'edit', ...
            'Tag', 'editAzimuth');

        % Elevation adjustment box:
        uicontrol(...
            'Background', bColor, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'HorizontalAlign', 'Left', ...
            'Parent', guiView, ...
            'Position', [10 16 60 24], ...
            'String', 'Elevation', ...
            'Style', 'text', ...
            'Tag', 'textElevation');

        editElevation = uicontrol(...
            'Background', bColor, ...
            'Callback', @editelevationcallback, ...
            'FontSize', 10, ...
            'Foreground', fColor, ...
            'KeyPressFcn', @editelevationkeypresscallback, ...
            'Parent', guiView, ...
            'Position', [75 20 50 24], ...
            'String', viewInitial(2), ...
            'Style', 'edit', ...
            'Tag', 'editElevation');

        %% Store the adjustment figure's handle in the appdata of the main figure.
        setappdata(graphTracks, 'guiView', guiView)

        %% Attach a listener to the axes to update the azimuth and elevation on a view change.
        addlistener(axesGraph, 'View', 'PostSet', ...
            @(propView, eventData)viewsync(propView, eventData, editAzimuth, editElevation));

        %% Nested functions for axes limit adjustments
        function editazimuthcallback(varargin)
            % EDITAZIMUTHCALLBACK
            %
            %

            %% Get the current axes x limits.
            currentView = get(axesGraph, 'View');

            %% Get the desired azimuth value.
            azValue = str2double(get(editAzimuth, 'String'));

            %% Test for a valid value, then update or reset.
            if ~isreal(azValue)
                % Reset the azimuth editbox value.
                set(editAzimuth, 'String', currentView(1))

            else
                % Update the axes view.
                set(axesGraph, 'View', [azValue currentView(2)])

            end % if
        end % editazimuthcallback

        function editelevationcallback(varargin)
            % EDITELEVATIONCALLBACK
            %
            %

            %% Get the current axes x limits.
            currentView = get(axesGraph, 'View');

            %% Get the elevation value.
            elValue = str2double(get(editElevation, 'String'));

            %% Test for a valid range, then update or reset.
            if ~isreal(elValue)
                % Reset the elevation editbox value.
                set(editElevation, 'String', currentView(2))

            else
                % Update the axes view.
                set(axesGraph, 'View', [currentView(1) elValue])

            end % if

        end % editelevationcallback
            
        function editazimuthkeypresscallback(varargin)
            % EDITAZIMUTHKEYPRESSCALLBACK Update the axes azimuth on up or down arrow
            %
            %

            %% Check for an up or down press.
            switch varargin{2}.Key

                case 'uparrow'
                    viewValue = get(gca, 'View');
                    viewValue(1) = viewValue(1) + 1;

                case 'downarrow'
                    viewValue = get(gca, 'View');
                    viewValue(1) = viewValue(1) - 1;

                otherwise
                    return

            end % switch

            %% Update the editbox.
            set(editAzimuth, 'String', viewValue(1))
            set(gca, 'View', viewValue)
        end % editazimuthkeypresscallback

        function editelevationkeypresscallback(varargin)
            % EDITELEVATIONKEYPRESSCALLBACK Update the axes elevation on up or down arrow
            %
            %

            %% Check for an up or down press.
            switch varargin{2}.Key

                case 'uparrow'
                    viewValue = get(gca, 'View');
                    viewValue(2) = viewValue(2) + 1;

                case 'downarrow'
                    viewValue = get(gca, 'View');
                    viewValue(2) = viewValue(2) - 1;

                otherwise
                    return

            end % switch

            %% Update the editbox.
            set(editElevation, 'String', viewValue(2))
            set(gca, 'View', viewValue)
        end % editelevationkeypresscallback
    end % setaxesview

    %% Listener functions to sync the adjustment figures and axes coordinate lines.
    function limitsync(~, eventData, editMin, editMax)
        % EDITSYNC Sync the limit adjustment figure values
        %
        %

        if ishandle(editMin)
            %% Get the limits.
            limitValue = eventData.NewValue;

            %% Set the edit min and max boxes.
            set(editMin, 'String', limitValue(1))
            set(editMax, 'String', limitValue(2))
        end % if
    end % limitsync

    function viewsync(~, eventData, editAzimuth, editElevation)
        % VIEWSYNC Sync the view adjustment figure values
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
    
    function coordsync(~, eventData)
        % COORDSYNC Sync the coordinate axes lines' ranges
        %
        %
        
            %% Get the limits.
            limitValue = eventData.NewValue;

            %% Update the axis line.
            switch eventData.Source.DataType

                case 'axesXLimType'
                    set(xAx, 'XData', limitValue)

                case 'axesYLimType'
                    set(yAx, 'YData', limitValue)

                case 'axesZLimType'
                    set(zAx, 'ZData', limitValue)                        

            end % switch        
    end % coordsync
    
    %% Close request functions for the axes adjustment windows
    function guilimitsclosereqfcn(guiLimits, ~, graphTracks)
        % GUILIMITSCLOSEREQFCN Close the limits figure
        %
        %

        %% Remove the adjustment figure handle from the main figure's appdata.
        rmappdata(graphTracks, 'guiLimits')

        %% Delete the limits adjustment figure.
        delete(guiLimits)
    end % guilimitsfigclosereqfcn

    function guiviewclosereqfcn(guiView, ~, graphTracks)
        % GUIVIEWCLOSEREQFCN Close the view figure
        %
        %

        %% Remove the adjustment figure handle from the main figure's appdata.
        rmappdata(graphTracks, 'guiView')

        %% Delete the view adjustment figure.
        delete(guiView)
    end % guiviewclosereqfcn
end % sortomatocenteredtracksgraph


function closerequestfcn(graphTracks, ~, guiSortomato)
    % CLOSEREQUESTFCN Close the figure and open adjustment windows
    %
    %

    %% Check for associated axes adjustment figures.
    guiLimits = getappdata(graphTracks, 'guiLimits');
    guiView = getappdata(graphTracks, 'guiView');

    %% Delete any adjustment figures.
    if ~isempty(guiLimits)
        delete(guiLimits)
    end % if

    if ~isempty(guiView)
        delete(guiView)
    end % if

    %% Remove the graph GUI handle from the base GUI appdata.
    % Get the graph GUI handles list from the base GUI.
    graphChildren = getappdata(guiSortomato, 'graphChildren');

    % Remove the current graph from the list.
    graphChildren(graphChildren == graphTracks) = [];

    % Replace the appdata.
    setappdata(guiSortomato, 'graphChildren', graphChildren)
        
    % Now delete the graph figure.
    delete(graphTracks);    
end % closerequestfcn

