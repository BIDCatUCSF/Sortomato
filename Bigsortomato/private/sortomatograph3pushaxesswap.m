function sortomatograph3pushaxesswap(~, ~, hSortomatoGraph)
    % SORTOMATOGRAPHPUSHAXESSWAP Summary of this function goes here
    %   Detailed explanation goes here
    
    %% Get the current x and y listbox selections.
    popupX = findobj(hSortomatoGraph, 'Tag', 'popupX');
    currentX = get(popupX, 'Value');
    
    popupY = findobj(hSortomatoGraph, 'Tag', 'popupY');
    currentY = get(popupY, 'Value');

    popupZ = findobj(hSortomatoGraph, 'Tag', 'popupZ');
    currentZ = get(popupZ, 'Value');

    %% Swap the x and y selections.
    set(popupX, 'Value', currentY);
    set(popupY, 'Value', currentX);

    %% Swap the axis labels.
    axesGraph = findobj(hSortomatoGraph, 'Tag', 'axesGraph');
    
    titleX = get(axesGraph, 'xlabel');
    currentXLabel = get(titleX, 'String');
    
    titleY = get(axesGraph, 'ylabel');
    currentYLabel = get(titleY, 'String');
    
    set(titleX, 'String', currentYLabel)
    set(titleY, 'String', currentXLabel)

    %% Swap the plot data.
    currentXValues = getappdata(axesGraph, 'xData');
    currentYValues = getappdata(axesGraph, 'yData');
    xData = currentYValues;
    yData = currentXValues;

    %% Update the x-y-z plot.
    hScatter = getappdata(axesGraph, 'hScatter');
    set(hScatter, ...
        'XData', xData, ...
        'YData', yData, ...
        'Visible', 'On', ...
        'XLimInclude', 'On', ...
        'YLimInclude', 'On')
    
    %% Update the stored appdata.
    setappdata(axesGraph, 'xData', xData)
    setappdata(axesGraph, 'yData', yData)
end % sortomatographpushaxesswap