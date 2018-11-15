function sortomatograph3logzscale(~, ~, axesGraph, axesMenu)
    % SORTOMATOGRAPH3LOGZSCALE Set the Sortomato axes to z-log scaling
    %   Axes context menus children are:
    %       'menuAxesLogZScale'
    %       'menuAxesLogYScale'
    %       'menuAxesLogXScale'
    %       'menuAxesLogScale'
    %       'menuAxesLinearScale'
    
    %% Set the axes scaling.
    set(axesGraph, 'XScale', 'linear', 'YScale', 'linear', 'ZScale', 'log')
    
    %% Update the context menu checkbox.
    menuChildren = get(axesMenu, 'Children');
    set(menuChildren, {'Checked'}, {'on'; 'off'; 'off'; 'off'; 'off'})
end % sortomatograph3logzscale