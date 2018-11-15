function graphlinearscale(~, ~, menuAxes, axesGraph)
    % graphlinearscale Set the Sortomato axes to linear scaling
    %   Axes context menus children are:
    %       'menuAxesLogYScale'
    %       'menuAxesLogXScale'
    %       'menuAxesLogScale'
    %       'menuAxesLinearScale'
    
    %% Set the axes scaling.
    set(axesGraph, 'XScale', 'linear', 'YScale', 'linear')
    
    %% Update the context menu checkbox.
    menuChildren = get(menuAxes, 'Children');
    set(menuChildren, {'Checked'}, {'off'; 'off'; 'off'; 'on'})
end % graphlinearscale