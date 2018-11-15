function graph3linearscale(~, ~, menuAxes, axesGraph)
    % GRAPH3LINEARSCALE Set the Sortomato axes to linear scaling
    %   Axes context menus children are:
    %       'menuAxesLogZScale'
    %       'menuAxesLogYScale'
    %       'menuAxesLogXScale'
    %       'menuAxesLogScale'
    %       'menuAxesLinearScale'
    
    %% Set the axes scaling.
    set(axesGraph, 'XScale', 'linear', 'YScale', 'linear', 'ZScale', 'linear')
    
    %% Update the context menu checkbox.
    menuChildren = get(menuAxes, 'Children');
    set(menuChildren, {'Checked'}, {'off'; 'off'; 'off'; 'off'; 'on'})
end % graph3linearscale