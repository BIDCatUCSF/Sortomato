function sortomatograph3logyscale(~, ~, axesGraph, axesMenu)
    % SORTOMATOGRAPH3LOGYSCALE Set the Sortomato axes to y-log scaling
    %   Axes context menus children are:
    %       'menuAxesLogZScale'
    %       'menuAxesLogYScale'
    %       'menuAxesLogXScale'
    %       'menuAxesLogScale'
    %       'menuAxesLinearScale'
    
    %% Set the axes scaling.
    set(axesGraph, 'XScale', 'linear', 'YScale', 'log', 'ZScale', 'linear')
    
    %% Update the context menu checkbox.
    menuChildren = get(axesMenu, 'Children');
    set(menuChildren, {'Checked'}, {'off'; 'on'; 'off'; 'off'; 'off'})
end % sortomatograph3logyscale