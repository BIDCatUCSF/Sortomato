function pushhighlightselectioncallback(~, ~, xObject, axesGraph, figSortomatoGraph)
    % PUSHHIGHLIGHTSELECTIONCALLBACK Highlight the data points of the selected
    % Imaris objects
    %
    %
    
    %% Get the selected Imaris objects.
    xSelectedObjects = xObject.GetSelectedIndices;
    
    %% Get the IDs of the graphed objects.
    statStruct = getappdata(figSortomatoGraph,'statStruct');
    xIDs = double(statStruct(1).Ids);
    
    rgnColorMask = ismember(xIDs, xSelectedObjects);
    xColor = rgb32bittotriplet(xObject.GetColorRGBA);
    
    %% Update the plot.
    hScatter = getappdata(axesGraph, 'hScatter');
    xData = getappdata(axesGraph, 'xData');
    yData = getappdata(axesGraph, 'yData');

    set(hScatter(1), ...
        'MarkerFaceColor', xColor, ...
        'XData', xData(~rgnColorMask), ...
        'YData', yData(~rgnColorMask))

    delete(findobj(axesGraph, 'Tag', 'hScatter2'))
    hScatter(2) = line(...
        'LineStyle', 'none', ...
        'Marker', 'd', ...
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceColor', 1 - xColor, ...
        'MarkerSize', 3, ...
        'Parent', axesGraph, ...
        'Tag', 'hScatter2', ...
        'XData', xData(rgnColorMask), ...
        'YData', yData(rgnColorMask));
    uistack(hScatter, 'bottom')

    %% Store the region color mask and scatter handle array.
    setappdata(axesGraph, 'rgnColorMask', rgnColorMask)
    setappdata(axesGraph, 'hScatter', hScatter);
end % pushhighlightselectioncallback