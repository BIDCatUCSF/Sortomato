function sortomatograph3logscale(~, ~, axesGraph, axesMenu)
    % SORTOMATOGRAPH3LOGSCALE Set the Sortomato axes to log scaling
    %   Axes context menus children are:
    %       'menuAxesLogZScale'
    %       'menuAxesLogYScale'
    %       'menuAxesLogXScale'
    %       'menuAxesLogScale'
    %       'menuAxesLinearScale'
    
    %% Set the axes scaling.
    set(axesGraph, 'XScale', 'log', 'YScale', 'log', 'ZScale', 'log')
    
    %% Update the context menu checkbox.
    menuChildren = get(axesMenu, 'Children');
    set(menuChildren, {'Checked'}, {'off'; 'off'; 'off'; 'on'; 'off'})
end % sortomatograph3logscale