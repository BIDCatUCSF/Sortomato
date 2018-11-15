function sortomatographtogglepan(togglePan, ~, hSortomatoGraph)
    % SORTOMATOGRAPHTOGGLEPAN Toggle interactive axes pan
    %   Detailed explanation goes here
    
    %% Untoggle the data cursor and zoom buttons.
    toggleDataCursor = findobj(hSortomatoGraph, 'Tag', 'toggleDataCursor');
    toggleZoom = findobj(hSortomatoGraph, 'Tag', 'toggleZoom');
    
    set([toggleDataCursor, toggleZoom], 'State', 'off')
    
    %% Toggle pan.
    if strcmp(get(togglePan, 'State'), 'on')
        pan(hSortomatoGraph, 'on')
        
    else
        pan(hSortomatoGraph, 'off')
        
    end % if
end % sortomatographtogglepan

