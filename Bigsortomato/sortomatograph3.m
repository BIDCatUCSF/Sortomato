function sortomatograph3(hObject, ~, statStruct, guiSortomato, varargin)
    % SORTOMATOGRAPH3 Graph and sort objects based on their properties
    %   Syntax
    %   ------
    %   SORTOMATOGRAPH3(hObject, eventData, hSortomatoBase)
    %   SORTOMATOGRAPH3(..., 'Color', 'k')
    %   
    %   Description
    %   -----------
    %   SORTOMATOGRAPH3(hObject, eventData, hSortomatoBase) creates a 3D
    %   sortomatograph when executed as a callback for hObject. The graph
    %   figure runs as a part of the Sortomato base GUI represented by the
    %   handle hSortomatoBase.
    %
    %   SORTOMATOGRAPH3(..., 'Color', 'k') creates a sortomatograph3 figure
    %   with a dark background.
    %   
    %   SORTOMATOGRAPH3 is a GUI to create xyz plots of the properties derived
    %   from segmented image objects.
    %
    %   ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %   license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Parse the inputs.
    sortomatograph3Parser = inputParser;
    
    addRequired(sortomatograph3Parser, 'hObject', @(arg)ishandle(arg))
    
    validationFcnArg1 = @(arg)all(isfield(arg, {'Ids', 'Name', 'Values'}));
    addRequired(sortomatograph3Parser, 'statStruct', validationFcnArg1)
    
    addRequired(sortomatograph3Parser, 'hSortomatoBase', @(arg)ishandle(arg))
        
    addOptional(sortomatograph3Parser, 'RegionName', '', ...
        @(arg)ischar(arg))

    parse(sortomatograph3Parser, hObject, statStruct, guiSortomato, varargin{:})
    
    %% Get the Imaris object and statistics.
    statStruct = getappdata(guiSortomato, 'statStruct');
    
    if get(hObject, 'Parent') == guiSortomato
        % Get the Imaris object from the base's popup menu.
        popupObjects = findobj(guiSortomato, 'Tag', 'popupObjects');
        xObject = getappdata(popupObjects, 'xObject');
        
        panelGraphType = findobj(guiSortomato, 'Tag', 'panelGraphType');
        radioSelection = get(panelGraphType, 'SelectedObject');

        switch get(radioSelection, 'Tag')

            case 'radioSinglets'
                graphTypeString = 'Singlets';

                % Keep the singlet stats.
                singletStatIdxs = getappdata(guiSortomato, 'singletStatIdxs');
                statStruct = statStruct(singletStatIdxs);

            case 'radioTracks'
                graphTypeString = 'Tracks';

                % Keep the track stats.
                trackStatIdxs = getappdata(guiSortomato, 'trackStatIdxs');
                statStruct = statStruct(trackStatIdxs);

        end % switch
    
        % Create the graph's title and get the lower-left corner of the calling
        % figure.
        graphName = [char(xObject.GetName) ':' graphTypeString];
        referencePos = get(guiSortomato, 'Position');
        
    else
        % Get the Imaris object from the parent graph.
        figParentGraph = get(get(hObject, 'Parent'), 'Parent');
        xObject = getappdata(figParentGraph, 'xObject');
        
        % Get the region being plotted from the parent graph.
        popupRegions = findobj(figParentGraph, 'Tag', 'popupRegions');
        popupString = get(popupRegions, 'String');
        regionName = popupString{get(popupRegions, 'Value')};
        
        % Determine if it's an in-region or out-of-region plot.
        outsidePlot = ~isempty(regexp(get(hObject, 'Tag'), '(Outside)', 'Match', 'Once'));
        
        % Create the graph's title and get the lower-left corner of the calling
        % figure.
        if outsidePlot
            graphName = [get(figParentGraph, 'Name') ':Not In ' regionName];
            
        else
            graphName = [get(figParentGraph, 'Name') ':In ' regionName];
        
        end % if
        
        referencePos = get(figParentGraph, 'Position');
        
    end % if

    %% Create the graph figure.
    guiWidth = 450;
    guiHeight = 470;
    guiPos = [...
        referencePos(1, 1) + 25, ...
        referencePos(1, 2) + referencePos(1, 4) - guiHeight - 50, ...
        guiWidth, ...
        guiHeight]; 
    
    figSortomatoGraph = figure(...
        'CloseRequestFcn', {@graphclose, guiSortomato}, ...
        'DockControls', 'off', ...
        'InvertHardCopy', 'off', ...
        'MenuBar', 'None', ...
        'Name', graphName, ...
        'NumberTitle', 'Off', ...
        'PaperPositionMode', 'auto', ...
        'Position', guiPos, ...
        'Renderer', 'ZBuffer', ...
        'ResizeFcn', {@graphresize}, ...
        'Tag', 'figSortomatoGraph3');
    
    % Setup the status bar.
    hStatus = statusbar(figSortomatoGraph, '');
    hStatus.CornerGrip.setVisible(false)
    
    hStatus.ProgressBar.setForeground(java.awt.Color.black)
    hStatus.ProgressBar.setString('')
    hStatus.ProgressBar.setStringPainted(true)
    
    %% Add the figure to the base's graph children.
    graphChildren = getappdata(guiSortomato, 'graphChildren');
    graphChildren = [graphChildren; figSortomatoGraph];
    setappdata(guiSortomato, 'graphChildren', graphChildren);

    %% Store the XT objects and data associated with the figure.
    xImarisApp = getappdata(guiSortomato, 'xImarisApp');
    setappdata(figSortomatoGraph, 'xImarisApp', xImarisApp)
    setappdata(figSortomatoGraph, 'guiSortomato', guiSortomato)
    setappdata(figSortomatoGraph, 'xObject', xObject)
    setappdata(figSortomatoGraph, 'statStruct', statStruct)
    
    %% Load the cdata struct and set the figure, font and region cycling colors.
    if any(get(guiSortomato, 'Color'))
        sortomatographCData = load('sortomatograph_cdata.mat');
        set(figSortomatoGraph, 'Color', 'w', 'ColorMap', wjet(64))
        bColor = 'w';
        bColorJava = java.awt.Color.white;
        fColor = 'k';

        colorOrder = [
            0 0 0;
            1 0 0;
            0 1 0;
            0 0 1;
            0 1 1;
            1 0 1;
            1 1 0;
            1 0.5 0
            0.5 0.5 0.5];

    else
        sortomatographCData = load('sortomatographK_cdata.mat');
        set(figSortomatoGraph, 'Color', 'k', 'ColorMap', jetbw(64))
        bColor = 'k';
        bColorJava = java.awt.Color.black;
        fColor = 'w';

        colorOrder = [
            1 1 1;
            1 0 0;
            0 1 0;
            0 0 1;
            0 1 1;
            1 0 1;
            1 1 0;
            1 0.5 0
            0.5 0.5 0.5];

    end % if
    
    %% Create the axes and axes context menu.
    axesGraph = axes(...
        'Color', 'None', ...
        'ColorOrder', colorOrder, ...
        'FontName', 'Arial', ...
        'FontSize', 11, ...
        'NextPlot', 'Add', ...
        'Parent', figSortomatoGraph, ...
        'Tag', 'axesGraph', ...
        'TickDir', 'Out', ...
        'Units', 'Pixels', ...
        'XColor', fColor, ...
        'YColor', fColor, ...
        'ZColor', fColor);
    
    set(axesGraph, ...
        'Position', [75 95 300 300])
    
    % Create the conext menu and options.
    menuAxes = uicontextmenu;
    set(axesGraph, 'uicontextmenu', menuAxes)
    
    uimenu(menuAxes, ...
        'Callback', {@graph3linearscale, menuAxes, axesGraph}, ...
        'Checked', 'on', ...
        'Label', 'Linear scaling', ...
        'Tag', 'menuAxesLinearScale')
    
    uimenu(menuAxes, ...
        'Callback', {@graph3logscale, menuAxes, axesGraph}, ...
        'Label', 'Log scaling', ...
        'Tag', 'menuAxesLogScale')
    
    uimenu(menuAxes, ...
        'Callback', {@graph3logxscale, menuAxes, axesGraph}, ...
        'Label', 'Log-x scaling', ...
        'Tag', 'menuAxesLogXScale')
    
    uimenu(menuAxes, ...
        'Callback', {@graph3logyscale, menuAxes, axesGraph}, ...
        'Label', 'Log-y scaling', ...
        'Tag', 'menuAxesLogYScale')
    
    uimenu(menuAxes, ...
        'Callback', {@graph3logzscale, axesGraph, menuAxes}, ...
        'Label', 'Log-z scaling', ...
        'Tag', 'menuAxesLogZScale')
    
    %%  Create a blank plot. 
    % Get the Imaris object's color for visual reference.
    xColor = rgb32bittotriplet(xObject.GetColorRGBA);
    
    % Note: line is faster than scatter, but scatter enables symbol patch manipulation.
    xData = nan(size(statStruct(1).Values));
    yData = nan(size(statStruct(1).Values));
    zData = nan(size(statStruct(1).Values));
    hScatter = line(...
        'LineStyle', 'none', ...
        'Marker', 'd', ...
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceColor', xColor, ...
        'MarkerSize', 3, ...
        'Parent', axesGraph, ...
        'Tag', 'hScatter', ...
        'XData', xData, ...
        'YData', yData, ...
        'ZData', zData);
    uistack(hScatter, 'bottom')
    
    % Store the plot and data variables.
    setappdata(axesGraph, 'hScatter', hScatter)
    setappdata(axesGraph, 'xData', xData)
    setappdata(axesGraph, 'yData', yData)
    setappdata(axesGraph, 'zData', zData)
    
    %% Create the figure area GUI elements.
    uicontrol(...
        'BackgroundColor', bColor, ...
        'FontSize', 14, ...
        'ForegroundColor', fColor, ...
        'Parent', figSortomatoGraph, ...
        'Position', [424 43 16 24], ...
        'String', 'X', ...
        'Style', 'text', ...
        'Tag', 'textX')
    
    uicontrol(...
        'BackgroundColor', bColor, ...
        'Callback', {@popupvariablegraph3callback, axesGraph, figSortomatoGraph}, ...
        'FontSize', 12, ...
        'ForegroundColor', fColor, ...
        'Parent', figSortomatoGraph, ...
        'Position', [400 45 16 24], ...
        'String', {statStruct.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupX', ...
        'TooltipString', 'Select a variable for the x axis', ...
        'Value', 1)

    uicontrol(...
        'BackgroundColor', bColor, ...
        'FontSize', 14, ...
        'ForegroundColor', fColor, ...
        'Parent', figSortomatoGraph, ...
        'Position', [10 424 16 24], ...
        'String', 'Y', ...
        'Style', 'text', ...
        'Tag', 'textY')
    
    uicontrol(...
        'BackgroundColor', bColor, ...
        'Callback', {@popupvariablegraph3callback, axesGraph, figSortomatoGraph}, ...
        'FontSize', 12, ...
        'ForegroundColor', fColor, ...
        'Parent', figSortomatoGraph, ...
        'Position', [34 45 16 24], ...
        'String', {statStruct.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupY', ...
        'TooltipString', 'Select a variable for the x axis', ...
        'Value', 1)

    uicontrol(...
        'BackgroundColor', bColor, ...
        'FontSize', 14, ...
        'ForegroundColor', fColor, ...
        'Parent', figSortomatoGraph, ...
        'Position', [424 424 16 24], ...
        'String', 'Z', ...
        'Style', 'text', ...
        'Tag', 'textZ')
    
    uicontrol(...
        'BackgroundColor', bColor, ...
        'Callback', {@popupvariablegraph3callback, axesGraph, figSortomatoGraph}, ...
        'FontSize', 12, ...
        'ForegroundColor', fColor, ...
        'Parent', figSortomatoGraph, ...
        'Position', [400 426 16 24], ...
        'String', {statStruct.Name}, ...
        'Style', 'popupmenu', ...
        'Tag', 'popupZ', ...
        'TooltipString', 'Select a variable for the z axis', ...
        'Value', 1)
    
    uicontrol(...
        'BackgroundColor', bColor, ...
        'FontSize', 14, ...
        'ForegroundColor', fColor, ...
        'Parent', figSortomatoGraph, ...
        'Position', [169 424 81 24], ...
        'String', 'Regions', ...
        'Style', 'text', ...
        'Tag', 'textRegions')
    
    %% Initialize default contour settings.
    % Set the default number of contour levels.
    setappdata(axesGraph, 'contourLevels', 64)
    
    % Create a default smoothing kernel.
    contourStrel = strel('disk', 3, 0);
    strelNhood = contourStrel.getnhood;
    contourKernel = strelNhood/sum(strelNhood(:));
    setappdata(axesGraph, 'contourKernel', contourKernel)
    
    % Store the colormap name.
    setappdata(axesGraph, 'colormapName', 'Jet')
    
    %% Create the toolbar and toolbar buttons.
    toolbarGraph = uitoolbar(figSortomatoGraph, ...
        'Tag', 'toolbarSortomatoGraph');

    uitoggletool(toolbarGraph, ...
        'CData', sortomatographCData.DataCursor, ...
        'ClickedCallback', {@toggledatacursorcallback, figSortomatoGraph}, ...
        'Tag', 'toggleDataCursor', ...
        'TooltipString', 'Activate the data cursor')
    
    uitoggletool(toolbarGraph, ...
        'CData', sortomatographCData.Zoom, ...
        'ClickedCallback', {@togglezoomcallback, figSortomatoGraph}, ...
        'Tag', 'toggleZoom', ...
        'TooltipString', 'Activate zooming')
    
    uitoggletool(toolbarGraph, ...
        'CData', sortomatographCData.Pan, ...
        'ClickedCallback', {@togglepancallback, figSortomatoGraph}, ...
        'Tag', 'togglePan', ...
        'TooltipString', 'Activate panning')
    
    uitoggletool(toolbarGraph, ...
        'CData', sortomatographCData.Rotate3D, ...
        'ClickedCallback', {@togglerotatecallback, figSortomatoGraph}, ...
        'Tag', 'toggleRotate', ...
        'TooltipString', 'Activate rotation')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatographCData.ManualLimits, ...
        'ClickedCallback', {@graph3manuallimits, figSortomatoGraph}, ...
        'Tag', 'pushManualLimits', ...
        'TooltipString', 'Set manual axes limits')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatographCData.SelectionHighlight, ...
        'ClickedCallback', {@pushhighlightselectioncallback, xImarisApp, xObject, axesGraph}, ...
        'Tag', 'pushGraphDataExport', ...
        'TooltipString', 'Highlight selected Imaris objects')

    uipushtool(toolbarGraph, ...
        'CData', sortomatographCData.GraphExport, ...
        'ClickedCallback', {@pushexportgraphcallback, figSortomatoGraph}, ...
        'Separator', 'on', ...
        'Tag', 'pushExportGraph', ...
        'TooltipString', 'Export the current graph')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatographCData.GraphDataExport, ...
        'ClickedCallback', {@pushexportgraphdatacallback, figSortomatoGraph}, ...
        'Tag', 'pushExportGraphData', ...
        'TooltipString', 'Export the current graph data')
    
    %% Set the toobar and button backgrounds.
    % Get the underlying JToolBar component.
    drawnow
    jToolbar = get(get(toolbarGraph, 'JavaContainer'), 'ComponentPeer');
    
    % Set the toolbar background color.
    jToolbar.setBackground(bColorJava);
    jToolbar.getParent.getParent.setBackground(bColorJava);
    
    jtbComponents = jToolbar.getComponents;
    for t = 1:length(jtbComponents)
        jtbComponents(t).setOpaque(false);
        jtbComponents(t).setBackground(bColorJava);
        
        for c = 1:length(jtbComponents(t).getComponents)
            jtbComponents(t).getComponent(c - 1).setBackground(bColorJava);
        end % for c
    end % for t

    % Set the toolbar more icon to a custom icon.
    javaImage = im2java(sortomatographCData.MoreToolbar);
    javaIcon = javax.swing.ImageIcon(javaImage);
    jtbComponents(1).setIcon(javaIcon)
    jtbComponents(1).setToolTipText('More tools')
    
    %% Create a color order, last region color and region tracking variables.
    setappdata(axesGraph, 'lastRegionColor', 0)
    
    regionStruct = struct();
    setappdata(axesGraph, 'regionStruct', regionStruct)
    setappdata(axesGraph, 'nextRegionTag', [1 1 1 1]) % [Ellipse Polygon Rectangle Freehand]
    setappdata(axesGraph, 'isUserDrawing', 0)
end % sortomatograph


function graphresize(figSortomatoGraph, ~)
    %
    %
    %
    
    %% Get the figure position.
    figurePos = get(figSortomatoGraph, 'Position');
        
    % Limit the minimum figure size.
    if figurePos(3) < 331
        figurePos(3) = 331;
        set(figSortomatoGraph, 'Position', figurePos)
    end % if
    
    if figurePos(4) < 261
        figurePos(2) = figurePos(2) + figurePos(4) - 261;
        figurePos(4) = 261;
        set(figSortomatoGraph, 'Position', figurePos)
    end % if
    
    %% Fix the x label relative to the lower-right corner.
    textX = findobj(figSortomatoGraph, 'Tag', 'textX');
    textXPos = get(textX, 'Position');

    % Change the x position.
    textXPos(1) = figurePos(3) - 26;

    % Update the position.
    set(textX, 'Position', textXPos)

    %% Fix the x popup relative to the lower-right corner.
    popupX = findobj(figSortomatoGraph, 'Tag', 'popupX');
    popupXPos = get(popupX, 'Position');

    % Change the x position.
    popupXPos(1) = figurePos(3) - 50;

    % Update the position.
    set(popupX, 'Position', popupXPos)

    %% Fix the y label relative to the upper-left corner.
    textY = findobj(figSortomatoGraph, 'Tag', 'textY');
    textYPos = get(textY, 'Position');

    % Change the y position.
    textYPos(2) = figurePos(4) - 46;

    % Update the position.
    set(textY, 'Position', textYPos)

    %% Fix the y popup relative to the upper-left corner.
    popupY = findobj(figSortomatoGraph, 'Tag', 'popupY');
    popupYPos = get(popupY, 'Position');

    % Change the y position.
    popupYPos(2) = figurePos(4) - 44;

    % Update the position.
    set(popupY, 'Position', popupYPos)

    %% Fix the z label relative to the upper-left corner.
    textRegions = findobj(figSortomatoGraph, 'Tag', 'textZ');
    textRegionsPos = get(textRegions, 'Position');

    % Change the x and y position.
    textRegionsPos(1) = figurePos(3) - 26;
    textRegionsPos(2) = figurePos(4) - 46;

    % Update the position.
    set(textRegions, 'Position', textRegionsPos)
    
    %% Fix the z popup relative to the upper-right corner.
    popupRegions = findobj(figSortomatoGraph, 'Tag', 'popupZ');
    popupRegionsPos = get(popupRegions, 'Position');

    % Change the x and y positions.
    popupRegionsPos(1) = figurePos(3) - 50;
    popupRegionsPos(2) = figurePos(4) - 44;

    % Update the position.
    set(popupRegions, 'Position', popupRegionsPos)

    %% Fix the regions label relative to the upper-left corner.
    textRegions = findobj(figSortomatoGraph, 'Tag', 'textRegions');
    textRegionsPos = get(textRegions, 'Position');

    % Change the x and y position.
    textRegionsPos(1) = figurePos(3) - 281;
    textRegionsPos(2) = figurePos(4) - 46;

    % Update the position.
    set(textRegions, 'Position', textRegionsPos)
    
    %% Fix the regions popup relative to the upper-right corner.
    popupRegions = findobj(figSortomatoGraph, 'Tag', 'popupRegions');
    popupRegionsPos = get(popupRegions, 'Position');

    % Change the x and y positions.
    popupRegionsPos(1) = figurePos(3) - 192;
    popupRegionsPos(2) = figurePos(4) - 44;

    % Update the position.
    set(popupRegions, 'Position', popupRegionsPos)

    %% Fix the axes relative to the lower-left and upper-right corners.
    axesGraph = findobj(figSortomatoGraph, 'Tag', 'axesGraph');
    axesPos = get(axesGraph, 'Position');

    % Change the width and height to pin the upper-right corner relative to the
    % window.
    axesPos(3) = figurePos(3) - 150;
    axesPos(4) = figurePos(4) - 170;

    % Update the position.
    set(axesGraph, 'Position', axesPos)    
end % graphresize


function graphclose(figSortomatoGraph, ~, guiSortomato)
    %
    %
    %

    %% Close the limits window if it exists.
    guiLimits = getappdata(figSortomatoGraph, 'guiLimits');
    if ishandle(guiLimits)
        delete(guiLimits)
    end % if
    
    %% Remove the graph GUI handle from the base GUI appdata.
    % Get the graph GUI handles list from the base GUI.
    graphChildren = getappdata(guiSortomato, 'graphChildren');

    % Remove the current graph from the list.
    graphChildren(graphChildren == figSortomatoGraph) = [];

    % Replace the appdata.
    setappdata(guiSortomato, 'graphChildren', graphChildren)
        
    % Now delete the GUI.
    delete(figSortomatoGraph);    
end % graphclose