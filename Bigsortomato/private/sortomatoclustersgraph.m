function [graphClusters, axesGraph] = sortomatoclustersgraph(guiClusters, clusterNumber, clusterAlgorithm, tSize, xObject, hSortomatoBase)
    % SORTOMATOCLUSTERSGRAPH Graph cluster analysis results
    %   Detailed explanation goes here
    
    %% Parse the inputs.
    % Because inputs are being passed from a Sortomato GUI, the only
    % parsing required is the Series Parameter/Value pair. All inputs are
    % parsed in case this is ever repackaged as a standalone tool.
    sortomatoclustersgraphParser = inputParser;
    
    addRequired(sortomatoclustersgraphParser, 'guiClusters', @(arg)ishandle(arg))
    addRequired(sortomatoclustersgraphParser, 'clusterNumber', ...
        @(arg)isnumeric(arg) && rem(arg, 1) == 0)
    addRequired(sortomatoclustersgraphParser, 'clusterAlgorithm', ...
        @(arg)any(strcmpi(arg, {'linkage', 'kmeans', 'Gaussian mixture'})))
    addRequired(sortomatoclustersgraphParser, 'tSize', ...
        @(arg)isnumeric(arg) && rem(arg, 1) == 0)
    addRequired(sortomatoclustersgraphParser, 'xObject')
    addRequired(sortomatoclustersgraphParser, 'hSortomatoBase', @(arg)ishandle(arg))
    
    parse(sortomatoclustersgraphParser, ...
        guiClusters, clusterNumber, clusterAlgorithm, tSize, xObject, hSortomatoBase)
    
    %% Set the figure and font colors.
    if all(get(guiClusters, 'Color') == [0 0 0])
        sortomatokmeansgraphCData = load('sortomatoclustersgraphK_cdata.mat');
        
        bColor = 'k';
        bColorJava = java.awt.Color.black;
        fColor = 'w';
        fColorJava = java.awt.Color.white;
        
        axColor = 0.75*ones(3, 1);
        
    else
        sortomatokmeansgraphCData = load('sortomatoclustersgraph_cdata.mat');
        bColor = 'w';
        bColorJava = java.awt.Color.white;
        fColor = 'k';
        fColorJava = java.awt.Color.black;
        
        axColor = 0.25*ones(3, 1);
        
    end % if
    
    %% Create the figure.
    parentPos = get(guiClusters, 'Position');
    
    guiWidth = 560;
    guiHeight = 420;
    guiPos = [...
        parentPos(1, 1) + 25, ...
        parentPos(1, 2) + parentPos(1, 4) - guiHeight - 50, ...
        guiWidth, ...
        guiHeight]; 
    
    graphClusters = figure(...
        'CloseRequestFcn', {@closerequestfcn, hSortomatoBase}, ...
        'Color', bColor, ...
        'DockControls', 'off', ...
        'InvertHardCopy', 'off', ...
        'MenuBar', 'None', ...
        'Name', [char(xObject.GetName)  ' ' num2str(clusterNumber)  '-' clusterAlgorithm ' silhouettes'], ...
        'NumberTitle', 'off', ...
        'PaperPositionMode', 'auto', ...
        'Position', guiPos, ...
        'Renderer', 'ZBuffer', ...
        'ResizeFcn', {@graphresize}, ...
        'Tag', 'graphClusters');
    
    axesGraph = axes(...
        'Color', 'None', ...
        'FontSize', 12, ...
        'Linewidth', 2, ...
        'Parent', graphClusters, ...
        'Tag', 'axesGraph', ...
        'TickDir', 'out', ...
        'Units', 'Pixels', ...
        'XColor', axColor, ...
        'YColor', axColor, ...
        'ZColor', axColor);

    set(axesGraph, 'Position', [50 50 484 316])
    
    %% Create the time slider if the data is a time series.
    if tSize > 1
        % Create the time label.
        uicontrol(...
            'Background', bColor, ...
            'FontSize', 14, ...
            'Foreground', fColor', ...
            'HorizontalAlign', 'Left', ...
            'Position', [317 378 100 24], ...
            'String', 'Time', ...
            'Style', 'Text', ...
            'Tag', 'textTime');
        
        % Get the object color to pass into the editbox and slider callback.
        barColor = rgb32bittotriplet(xObject.GetColorRGBA);
        
        % Create the edit box.
        editTime = mycontrol(...
            'Background', bColor, ...
            'FontSize', 12, ...
            'Foreground', fColor, ...
            'Parent', graphClusters, ...
            'Position', [374 376 50 24], ...
            'String', 2, ...
            'Style', 'edit', ...
            'Tag', 'editTime', ...
            'TooltipString', 'Enter the time point', ...
            'Value', 1);
        set(editTime.Handle, 'Callback', ...
            {@editcallback, editTime, graphClusters, axesGraph, axColor, barColor, tSize})

        % Create the time slider.
        uicomponent(...
            'Background', bColorJava, ...
            'Foreground', fColorJava, ...
            'KeyReleasedCallback', {@slidertimecallback, axesGraph, graphClusters, axColor, barColor}, ...
            'Minimum', 1, ...
            'Maximum', tSize, ...
            'MouseReleasedCallback', {@slidertimecallback, axesGraph, graphClusters, axColor, barColor}, ...
            'Name', 'sliderTime', ...
            'Parent', graphClusters, ...
            'Position', [434 376 100 24], ...
            'Style', 'javax.swing.jslider', ...
            'ToolTipText', num2str(1, '%u'), ...
            'Value', 1);
    end % if
        
    %% Create the toolbar and toolbar buttons.
    toolbarGraph = uitoolbar(graphClusters, ...
        'Tag', 'toolbarMSDGraph');

    % Create the toolbar buttons.
    uitoggletool(toolbarGraph, ...
        'CData', sortomatokmeansgraphCData.DataCursor, ...
        'ClickedCallback', {@sortomatographtoggledatacursor, graphClusters}, ...
        'Tag', 'toggleDataCursor', ...
        'TooltipString', 'Activate the data cursor')
    
    uitoggletool(toolbarGraph, ...
        'CData', sortomatokmeansgraphCData.Zoom, ...
        'ClickedCallback', {@sortomatographtogglezoom, graphClusters}, ...
        'Tag', 'toggleZoom', ...
        'TooltipString', 'Activate zooming')
    
    uitoggletool(toolbarGraph, ...
        'CData', sortomatokmeansgraphCData.Pan, ...
        'ClickedCallback', {@sortomatographtogglepan, graphClusters}, ...
        'Tag', 'togglePan', ...
        'TooltipString', 'Activate panning')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatokmeansgraphCData.ClusterReturn, ...
        'ClickedCallback', {@sortomatoclustersclusterreturn, graphClusters, clusterNumber, clusterAlgorithm}, ...
        'Separator', 'on', ...
        'Tag', 'pushClustersReturn', ...
        'TooltipString', 'Transfer the cluster indices to Imaris')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatokmeansgraphCData.CentroidReturn, ...
        'ClickedCallback', {@sortomatoclusterscentroidreturn, graphClusters, clusterNumber, clusterAlgorithm}, ...
        'Tag', 'pushCentroidsReturn', ...
        'TooltipString', 'Transfer the cluster centroids to Imaris')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatokmeansgraphCData.GraphExport, ...
        'ClickedCallback', {@sortomatographpushgraphexport, graphClusters}, ...
        'Separator', 'on', ...
        'Tag', 'pushGraphExport', ...
        'TooltipString', 'Export the current graph')
    
    uipushtool(toolbarGraph, ...
        'CData', sortomatokmeansgraphCData.GraphDataExport, ...
        'ClickedCallback', {@sortomatographpushdataexport, graphClusters}, ...
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
    javaImage = im2java(sortomatokmeansgraphCData.MoreToolbar);
    javaIcon = javax.swing.ImageIcon(javaImage);
    jtbComponents(1).setIcon(javaIcon)
    jtbComponents(1).setToolTipText('More tools')
                
    %% Add the figure to the base's graph children.
    graphChildren = getappdata(hSortomatoBase, 'graphChildren');
    graphChildren = [graphChildren; graphClusters];
    setappdata(hSortomatoBase, 'graphChildren', graphChildren)
end % sortomatoclustersgraph


%% Callback function to validate editbox changes
function editcallback(hObject, ~, hObjectContainer, graphKMeans, axesGraph, axColor, barColor, tSize)
    % EDITCALLBACK Verify string conversion to numeric and update plot
    %
    %

    %% Update the editbox value and plot if the input is numeric.
    newValue = str2double(get(hObject, 'String'));

    if isnan(newValue) || newValue < 1 || newValue > tSize
        set(hObject, 'String', hObjectContainer.OldString)

    else
        %% Round the value to an index.
        tIdx = round(newValue);
        
        set(hObject, 'String', tIdx)
        hObjectContainer.OldString = tIdx;
        
        %% Update the slider.
        sliderTime = findobj(graphKMeans, 'Tag', 'sliderTime');
        set(sliderTime, 'ToolTipText', num2str(tIdx, '%u'))
        set(sliderTime, 'Value', tIdx)
    
        %% Plot the silhouettes for the selected time point.
        structClusters = getappdata(graphKMeans, 'structClusters');
        [~, ~] = silhouette(structClusters(tIdx).Pos, structClusters(tIdx).KIdx);

        %% Format the silhoutte plot.
        % Format the axes.
        set(axesGraph, ...
            'Box', 'off', ...
            'Color', 'None', ...
            'FontSize', 12, ...
            'Linewidth', 2, ...
            'Tag', 'axesGraph', ...
            'TickDir', 'Out', ...
            'Units', 'Pixels', ...
            'XColor', axColor, ...
            'YColor', axColor, ...
            'ZColor', axColor)

        %% Format and tag the bar plot.
        barSilhouettes = get(axesGraph, 'Children');
        set(barSilhouettes, 'FaceColor', 'flat', 'Tag', 'barSilhouettes')

        patchSilhouettes = get(barSilhouettes, 'Children');
        set(patchSilhouettes, 'FaceVertexCData', barColor)

        silBaseLine = get(barSilhouettes, 'BaseLine');
        set(silBaseLine, 'Color', axColor)

    end % if
end % editcallback


function slidertimecallback(sliderTime, ~, axesGraph, graphKMeans, axColor, barColor)
    % SLIDERTIMECALLBACK Update the plotted clusters
    %
    %
    
    %% Get the selected time point.
    tIdx = round(get(sliderTime, 'Value'));
    set(sliderTime, 'ToolTipText', num2str(tIdx, '%u'))
    
    %% Update the edit box.
    editTime = findobj(graphKMeans, 'Tag', 'editTime');
    set(editTime, 'String', tIdx)
    
    %% Plot the silhouettes for the selected time point.
    structClusters = getappdata(graphKMeans, 'structClusters');
    [~, ~] = silhouette(structClusters(tIdx).Pos, structClusters(tIdx).KIdx);

    %% Format the silhoutte plot.
    % Format the axes.
    set(axesGraph, ...
        'Box', 'off', ...
        'Color', 'None', ...
        'FontSize', 12, ...
        'Linewidth', 2, ...
        'Tag', 'axesGraph', ...
        'TickDir', 'Out', ...
        'Units', 'Pixels', ...
        'XColor', axColor, ...
        'YColor', axColor, ...
        'ZColor', axColor)

    % Format and tag the bar plot.
    barSilhouettes = get(axesGraph, 'Children');
    set(barSilhouettes, 'FaceColor', 'flat', 'Tag', 'barSilhouettes')

    silPatches = get(barSilhouettes, 'Children');
    set(silPatches, 'FaceVertexCData', barColor)

    silBaseLine = get(barSilhouettes, 'BaseLine');
    set(silBaseLine, 'Color', axColor)
end % slidertimecallback


function graphresize(hFigure, ~)
    % GRAPHRESIZE Resize the k-means silhoute graph
    %
    %
    
    %% Get the figure position.
    figurePos = get(hFigure, 'Position');
    
    %% Fix the time selection GUI elements relative to the upper-right corner.
    sliderTime = findobj(hFigure, 'Name', 'sliderTime');
    
    if ~isempty(sliderTime)
        % Get the slider position.
        sliderPos = get(sliderTime, 'Position');

        % Change the slider x and y positions.
        sliderPos(1) = figurePos(3) - 126;
        sliderPos(2) = figurePos(4) - 44;

        % Update the slider position.
        set(sliderTime, 'Position', sliderPos)
        
        % Update the edit box.
        editTime = findobj(hFigure, 'Tag', 'editTime');
        
        editPos = get(editTime, 'Position');
        editPos(1) = figurePos(3) - 186;
        editPos(2) = figurePos(4) - 44;
        
        set(editTime, 'Position', editPos)
        
        % Update the text label.
        textTime = findobj(hFigure, 'Tag', 'textTime');
        
        textPos = get(textTime, 'Position');
        textPos(1) = figurePos(3) - 243;
        textPos(2) = figurePos(4) - 44;
        
        set(textTime, 'Position', textPos)        
    end % if
    
    %% Fix the axes relative to the lower-left and upper-right corners.
    axesGraph = findobj(hFigure, 'Tag', 'axesGraph');

    % Get the position.
    axesPos = get(axesGraph, 'Position');

    % Change the width and height to pin the upper-right corner relative to the
    % window.
    axesPos(3) = figurePos(3) - 76;
    axesPos(4) = figurePos(4) - 94;

    % Update the position.
    set(axesGraph, 'Position', axesPos)    
end % graphresize


function closerequestfcn(hObject, ~, hSortomatoBase)
    % Close the k-means graph
    %
    %
    
    %% Remove the graph GUI handle from the base GUI appdata.
    % Get the graph GUI handles list from the base GUI.
    graphChildren = getappdata(hSortomatoBase, 'graphChildren');

    % Remove the current graph from the list.
    graphChildren(graphChildren == hObject) = [];

    % Replace the appdata.
    setappdata(hSortomatoBase, 'graphChildren', graphChildren)
        
    % Now delete the graph figure.
    delete(hObject);    
end % closerequestfcn    
