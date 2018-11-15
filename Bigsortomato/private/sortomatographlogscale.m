function sortomatographlogscale(~, ~, axesGraph, axesMenu)
    % SORTOMATOGRAPHLOGSCALE Set the Sortomato axes to log scaling
    %   Axes context menus children are:
    %       'menuAxesLogYScale'
    %       'menuAxesLogXScale'
    %       'menuAxesLogScale'
    %       'menuAxesLinearScale'
    
    %% Set the axes scaling.
    set(axesGraph, 'XScale', 'log', 'YScale', 'log')
    
    %% Update the context menu checkbox.
    menuChildren = get(axesMenu, 'Children');
    set(menuChildren, {'Checked'}, {'off'; 'off'; 'on'; 'off'})
end % sortomatographlogscale